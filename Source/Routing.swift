//
//  Routing.swift
//  Routing
//
//  Created by Jason Prasad on 9/28/15.
//  Copyright © 2015 Routing. All rights reserved.
//

import Foundation

public typealias Parameters = [String: String]

protocol Routable {
    associatedtype Handler
    
    var pattern: String { get set }
    var dynamicSegments: [String] { get set }
    var queue: dispatch_queue_t { get set }
    var handler: Handler { get set }
    
    init(pattern: String, dynamicSegments: [String], queue: dispatch_queue_t, handler: Handler)
    static func register(pattern: String, queue: dispatch_queue_t, handler: Handler) -> Self
    func matches(route: String, inout parameters: Parameters) -> Bool
}

extension Routable {
    static func register(pattern: String, queue: dispatch_queue_t, handler: Handler) -> Self {
        var pattern = pattern
        var dynamicSegments = [String]()
        while let range = pattern.rangeOfString(":[a-zA-Z0-9-_]+", options: [.RegularExpressionSearch, .CaseInsensitiveSearch]) {
            dynamicSegments.append(pattern.substringWithRange(range).stringByReplacingOccurrencesOfString(":", withString: ""))
            pattern.replaceRange(range, with: "([^/]+)")
        }
        
        return self.init(pattern: pattern, dynamicSegments: dynamicSegments, queue: queue, handler: handler)
    }
    
    func matches(route: String, inout parameters: Parameters) -> Bool {
        guard let matches = (try? NSRegularExpression(pattern: pattern, options: .CaseInsensitive))
            .flatMap({ $0.matchesInString(route, options: [], range: NSMakeRange(0, route.characters.count)) })?
            .first else {
                return false
        }
        
        if dynamicSegments.count > 0 && dynamicSegments.count == matches.numberOfRanges - 1 {
            [Int](1 ..< matches.numberOfRanges).forEach { (index) in
                parameters[dynamicSegments[index-1]] = (route as NSString).substringWithRange(matches.rangeAtIndex(index))
            }
        }
        
        return true
    }
}

public struct Route: Routable {
    public typealias MapHandler = (String, Parameters, Completed) -> Void
    public typealias Completed = () -> Void
    
    var pattern: String
    var dynamicSegments: [String]
    var queue: dispatch_queue_t
    var handler: MapHandler
    
    init(pattern: String, dynamicSegments: [String], queue: dispatch_queue_t, handler: MapHandler) {
        self.pattern = pattern
        self.dynamicSegments = dynamicSegments
        self.queue = queue
        self.handler = handler
    }
}

public struct Proxy: Routable {
    public typealias ProxyHandler = (String, Parameters, Next) -> Void
    public typealias Next = (String?, Parameters?) -> Void
    
    var pattern: String
    var dynamicSegments: [String]
    var queue: dispatch_queue_t
    var handler: ProxyHandler
    
    init(pattern: String, dynamicSegments: [String], queue: dispatch_queue_t, handler: ProxyHandler) {
        self.pattern = pattern
        self.dynamicSegments = dynamicSegments
        self.queue = queue
        self.handler = handler
    }
}

public final class Routing {
    private var routes: [Route] = [Route]()
    private var proxies: [Proxy] = [Proxy]()
    private var accessQueue = dispatch_queue_create("Routing Access Queue", DISPATCH_QUEUE_SERIAL)
    private var routingQueue = dispatch_queue_create("Routing Queue", DISPATCH_QUEUE_SERIAL)
    
    internal init(){}
    
    public func map(pattern: String,
                    queue: dispatch_queue_t = dispatch_get_main_queue(),
                    handler: Route.MapHandler) -> Void {
        dispatch_async(accessQueue) {
            self.routes.insert(Route.register(pattern, queue: queue, handler: handler), atIndex: 0)
        }
    }
    
    public func proxy(pattern: String,
                      queue: dispatch_queue_t = dispatch_get_main_queue(),
                      handler: Proxy.ProxyHandler) -> Void {
        dispatch_async(accessQueue) {
            self.proxies.insert(Proxy.register(pattern, queue: queue, handler: handler), atIndex: 0)
        }
    }
    
    public func open(string: String) -> Bool {
        guard let URL = NSURL(string: string) else {
            return false
        }
        
        return open(URL)
    }
    
    public func open(URL: NSURL) -> Bool {
        var routes: [Route]!, proxies: [Proxy]!
        dispatch_sync(accessQueue) {
            routes = self.routes
            proxies = self.proxies
        }
        
        if routes.count == 0 {
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
        
        var matchedRoute: Route!
        var parameters: Parameters
        for route in routes {
            if route.matches(URLString, parameters: &parameters) {
                break
            }
        }
        
        if let routeComponents = filterRoute(URLString, routes: routes).first {
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
                        (overwrittingRoute.map { self.filterRoute($0, routes: routes).first } ?? routeComponents) {
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
}
