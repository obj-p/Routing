//
//  Routing.swift
//  Routing
//
//  Created by Jason Prasad on 9/28/15.
//  Copyright © 2015 Routing. All rights reserved.
//

import Foundation

/**
 */

public typealias Parameters = [String: String]

/**
 The closure type associated with #map
 
 - Parameter Parameters:  Any query parameters or dynamic segments found in the URL
 - Parameter Completed: Must be called for Routing to continue processing other routes with #open
 */

public typealias MapHandler = (String, Parameters, Completed) -> Void
public typealias Completed = () -> Void

/**
 The closure type associated with #proxy
 
 - Parameter String:  The route being opened
 - Parameter Parameters:  Any query parameters or dynamic segments found in the URL
 - Parameter Next: Must be called for Routing to continue processing. Calling #Next with
 nil arguments will continue executing other matching proxies. Calling #Next with non nil
 arguments will continue to process the route.
 */

public typealias ProxyHandler = (String, Parameters, Next) -> Void
public typealias Next = (String?, Parameters?) -> Void

private typealias Map = (String) -> (dispatch_queue_t, MapHandler?, Parameters)
private typealias Proxy = (String) -> (dispatch_queue_t, ProxyHandler?, Parameters)

public class BaseRouting {
    
    private var maps: [Map] = [Map]()
    private var proxies: [Proxy] = [Proxy]()
    private var accessQueue = dispatch_queue_create("Routing Access Queue", DISPATCH_QUEUE_CONCURRENT)
    private var routingQueue = dispatch_queue_create("Routing Queue", DISPATCH_QUEUE_SERIAL)
    
    internal init(){}
    
    internal func map(pattern: String,
        queue: dispatch_queue_t = dispatch_get_main_queue(),
        handler: MapHandler) -> Void {
            dispatch_barrier_async(accessQueue) {
                self.maps.insert(self.prepare(pattern, queue: queue, handler: handler), atIndex: 0)
            }
    }
    
    internal func proxy(pattern: String,
        queue: dispatch_queue_t = dispatch_get_main_queue(),
        handler: ProxyHandler) -> Void {
            dispatch_barrier_async(accessQueue) {
                self.proxies.insert(self.prepare(pattern, queue: queue, handler: handler), atIndex: 0)
            }
    }
    
    internal func open(string: String) -> Bool {
        guard let URL = NSURL(string: string) else {
            return false
        }
        
        return open(URL)
    }
    
    internal func open(URL: NSURL) -> Bool {
        var maps: [Map]!
        var proxies: [Proxy]!
        dispatch_sync(accessQueue) {
            maps = self.maps
            proxies = self.proxies
        }
        
        if maps.count == 0 {
            return false
        }
        
        guard let components = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false) else {
            return false
        }
        
        var queryParameters: [String: String] = [:]
        components.queryItems?.forEach() {
            queryParameters.updateValue(($0.value ?? ""), forKey: $0.name)
        }
        components.query = nil
        var URLString = components.string ?? ""
        
        if let routeComponents = filterRoute(URLString, routes: maps).first {
            defer {
                dispatch_async(routingQueue) {
                    let semaphore = dispatch_semaphore_create(0)
                    var overwrittingRoute: String?, overwrittingParameters: Parameters?
                    for (queue, handler, var parameters) in self.filterRoute(URLString, routes: proxies) {
                        queryParameters.forEach { parameters[$0.0] = $0.1 }
                        dispatch_async(queue) {
                            handler(URLString, parameters) { (route, parameters) in
                                overwrittingRoute = route
                                overwrittingParameters = parameters
                                dispatch_semaphore_signal(semaphore)
                            }
                        }
                        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
                        if overwrittingRoute != nil || overwrittingParameters != nil {
                            break
                        }
                    }
                    
                    if let (queue, handler, parameters) =
                        (overwrittingRoute.map { self.filterRoute($0, routes: maps).first } ?? routeComponents) {
                            var parameters = parameters
                            (overwrittingParameters ?? queryParameters).forEach {
                                parameters[$0.0] = $0.1
                            }
                            dispatch_async(queue) { handler(overwrittingRoute ?? URLString, parameters) {
                                dispatch_semaphore_signal(semaphore) }
                            }
                            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
                    }
                }
            }
            return true
        }
        return false
    }
    
    private func prepare<H>(var pattern: String,
        queue: dispatch_queue_t,
        handler: H) -> ((String) -> (dispatch_queue_t, H?, Parameters)) {
        var dynamicSegments = [String]()
        while let range = pattern.rangeOfString(":[a-zA-Z0-9-_]+", options: [.RegularExpressionSearch, .CaseInsensitiveSearch]){
            dynamicSegments.append(pattern.substringWithRange(range).stringByReplacingOccurrencesOfString(":", withString: ""))
            pattern.replaceRange(range, with: "([^/]+)")
        }
        
        return { (route: String) -> (dispatch_queue_t, H?, Parameters) in
            guard let matches = (try? NSRegularExpression(pattern: pattern, options: .CaseInsensitive))
                .flatMap({ $0.matchesInString(route, options: [], range: NSMakeRange(0, route.characters.count)) })?
                .first else {
                    return (queue, nil, [:])
            }
            
            var parameters = Parameters()
            if dynamicSegments.count > 0 && dynamicSegments.count == matches.numberOfRanges - 1 {
                [Int](1 ..< matches.numberOfRanges).forEach { (index) in
                    parameters[dynamicSegments[index-1]] = (route as NSString).substringWithRange(matches.rangeAtIndex(index))
                }
            }
            return (queue, handler, parameters)
        }
    }
    
    private func filterRoute<H>(route: String,
        routes: [(String) -> (dispatch_queue_t, H?, Parameters)]) -> [(dispatch_queue_t, H, Parameters)] {
        return routes
            .map { $0(route) }
            .filter { $0.1 != nil }
            .map { ($0, $1!, $2) }
    }
    
}
