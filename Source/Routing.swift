//
//  Routing.swift
//  Routing
//
//  Created by Jason Prasad on 9/28/15.
//  Copyright © 2015 Routing. All rights reserved.
//

import Foundation

public class Routing {
    
    public typealias MapHandler = (Parameters, Completed) -> Void
    public typealias Completed = () -> Void
    public typealias ProxyHandler = (String, Parameters, Next) -> Void
    public typealias Next = (String, Parameters) -> Void
    public typealias Parameters = [String: String]
    
    private var accessQueue: dispatch_queue_t!
    private var routingQueue: dispatch_queue_t!
    private var callbackQueue: dispatch_queue_t!
    private typealias Map = (String) -> (MapHandler?, Parameters)
    private var maps: [Map] = [Map]()
    private typealias Proxy = (String) -> (ProxyHandler?, Parameters)
    private var proxies: [Proxy] = [Proxy]()
    
    public init(accessQueue: dispatch_queue_t = dispatch_queue_create("Routing Access Queue", DISPATCH_QUEUE_CONCURRENT),
        routingQueue: dispatch_queue_t = dispatch_queue_create("Routing Queue", DISPATCH_QUEUE_SERIAL),
        callbackQueue: dispatch_queue_t = dispatch_get_main_queue()) {
            self.accessQueue = accessQueue
            self.routingQueue = routingQueue
            self.callbackQueue = callbackQueue
    }
    
    public func map(pattern: String, handler: MapHandler) -> Void {
        dispatch_barrier_async(accessQueue) {
            self.maps.insert(self.prepare(pattern, handler: handler), atIndex: 0)
        }
    }
    
    public func proxy(pattern: String, handler: ProxyHandler) -> Void {
        dispatch_barrier_async(accessQueue) {
            self.proxies.insert(self.prepare(pattern, handler: handler), atIndex: 0)
        }
    }
    
    public func open(URL: NSURL) -> Bool {
        var maps: [Map]!
        var proxies: [Proxy]!
        dispatch_sync(accessQueue) {
            maps = self.maps
            proxies = self.proxies
        }
        
        if maps.count == 0 { return false }
        guard let components = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false) else { return false }
        
        var queryParameters: [String: String] = [:]
        components.queryItems?.forEach() { queryParameters.updateValue(($0.value ?? ""), forKey: $0.name) }
        components.query = nil
        var URLString = components.string ?? ""
        
        if let routeComponents = filterRoute(URLString, routes: maps).first {
            defer { process(URLString, parameters: queryParameters, maps: maps, proxies: proxies) }
            return true
        }
        return false
    }
    
    private func process(route: String, parameters: [String: String], maps: [Map], proxies: [Proxy]) {
        dispatch_async(routingQueue) {
            let semaphore = dispatch_semaphore_create(0)
            // TODO: allow proxy to abort
            var overwrittenRoute = route, overwrittenParameters = parameters
            self.filterRoute(route, routes: proxies)
                .forEach { (handler, var parameters) in
                    overwrittenParameters.forEach { parameters[$0.0] = $0.1 }
                    dispatch_async(self.callbackQueue) {
                        handler(route, parameters) { (overwrittingRoute, overwrittingParameters) in
                            overwrittingParameters.forEach { overwrittenParameters[$0.0] = $0.1 }
                            overwrittenRoute = overwrittingRoute
                            dispatch_semaphore_signal(semaphore)
                        }
                    }
                    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            }

            if let (handler, parameters) = self.filterRoute(overwrittenRoute, routes: maps).first {
                var parameters = parameters
                overwrittenParameters.forEach { parameters[$0.0] = $0.1 }
                dispatch_async(self.callbackQueue) { handler(parameters) { dispatch_semaphore_signal(semaphore) } }
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            }
        }
    }
    
    private func filterRoute<H>(route: String, routes: [(String) -> (H?, Parameters)]) -> [(H, Parameters)] {
        return routes
            .map { $0(route) }
            .filter { $0.0 != nil }
            .map { ($0!, $1) }
    }
    
    private func prepare<H>(var pattern: String, handler: H) -> ((String) -> (H?, Parameters)) {
        var dynamicSegments = [String: String]()
        while let range = pattern.rangeOfString(":[a-zA-Z0-9-_]+", options: [.RegularExpressionSearch, .CaseInsensitiveSearch]) {
            dynamicSegments[pattern.substringWithRange(range).stringByReplacingOccurrencesOfString(":", withString: "")] = ""
            pattern.replaceRange(range, with: "([^/]+)")
        }
        
        return { (route: String) -> (H?, Parameters) in
            guard let matches = (try? NSRegularExpression(pattern: pattern, options: .CaseInsensitive))
                .flatMap({ $0.matchesInString(route, options: [], range: NSMakeRange(0, route.characters.count)) })?
                .first
            else {
                return (nil, [:])
            }

            if dynamicSegments.count == matches.numberOfRanges - 1 {
                print(matches.numberOfRanges)
                [Int](1 ..< matches.numberOfRanges).forEach { (index) in
                    
//                    dynamicSegments[] = (route as NSString).substringWithRange(matches.rangeAtIndex(index))
                }
            }

            return (handler, dynamicSegments)
        }
    }
    
}
