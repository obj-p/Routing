//
//  Routing.swift
//  Routing
//
//  Created by Jason Prasad on 9/28/15.
//  Copyright © 2015 Routing. All rights reserved.
//

import Foundation

public class Routing {
    public typealias ProxyHandler = (String, Parameters, Next) -> Void
    public typealias Next = (String, Parameters) -> Void
    public typealias RouteHandler = (Parameters, Completed) -> Void
    public typealias Parameters = [String: String]
    public typealias Completed = () -> Void
    
    private var accessQueue: dispatch_queue_t!
    private var routingQueue: dispatch_queue_t!
    private var callbackQueue: dispatch_queue_t!
    private typealias Proxy = (String) -> (ProxyHandler?, Parameters)
    private var proxies: [Proxy] = [Proxy]()
    private typealias Route = (String) -> (RouteHandler?, Parameters)
    private var routes: [Route] = [Route]()
    
    public init(accessQueue: dispatch_queue_t = dispatch_queue_create("Routing Access Queue", DISPATCH_QUEUE_CONCURRENT),
        routingQueue: dispatch_queue_t = dispatch_queue_create("Routing Queue", DISPATCH_QUEUE_SERIAL),
        callbackQueue: dispatch_queue_t = dispatch_get_main_queue()) {
            self.accessQueue = accessQueue
            self.routingQueue = routingQueue
            self.callbackQueue = callbackQueue
    }
    
    public func proxy(pattern: String, handler: ProxyHandler) -> Void {
        dispatch_barrier_async(accessQueue) {
            self.proxies.insert(self.prepare(pattern, handler: handler), atIndex: 0)
        }
    }
    
    public func map(pattern: String, handler: RouteHandler) -> Void {
        dispatch_barrier_async(accessQueue) {
            self.routes.insert(self.prepare(pattern, handler: handler), atIndex: 0)
        }
    }
    
    public func open(URL: NSURL) -> Bool {
        var proxies: [Proxy]!
        var routes: [Route]!
        dispatch_sync(accessQueue) {
            proxies = self.proxies
            routes = self.routes
        }
        
        if routes.count == 0 { return false }
        guard let components = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false) else {
            return false
        }
        
        var parameters: [String: String] = [:]
        components.queryItems?.forEach() {
            parameters.updateValue(($0.value ?? ""), forKey: $0.name)
        }
        components.query = nil
        var URLString = components.string ?? ""
        
        // TODO: extract common pattern
        let route = routes
            .map { $0(URLString) }
            .filter { $0.0 != nil }
            .first
            .map { ($0!, $1) }
        
        if let route = route {
            defer {
                process(URLString, parameters: parameters, proxies: proxies, route: route, routes: routes)
            }
            
            return true
        }
        
        return false
    }
    
    private func process(var path: String, var parameters: [String: String], proxies: [Proxy], var route: (RouteHandler, Parameters), routes: [Route]) {
        dispatch_async(routingQueue) {
            let semaphore = dispatch_semaphore_create(0)
            // TODO: allow proxy to abort
            proxies
                .map { $0(path) }
                .filter { $0.0 != nil }
                .map { ($0!, $1) }
                .forEach { (h, var p) in
                    parameters.forEach { p[$0.0] = $0.1 }
                    dispatch_async(self.callbackQueue) {
                        h(path, p) { (proxiedPath, proxiedParameters) in
                            proxiedParameters.forEach { parameters[$0.0] = $0.1 }
                            path = proxiedPath
                            dispatch_semaphore_signal(semaphore)
                        }
                    }
                    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            }

            route = routes
                .map { $0(path) }
                .filter { $0.0 != nil }
                .first
                .map { ($0!, $1) } ?? route
            
            parameters.forEach { route.1[$0.0] = $0.1 }
            dispatch_async(self.callbackQueue) {
                route.0(route.1) {
                    dispatch_semaphore_signal(semaphore)
                }
            }
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        }
    }
    
    private func prepare<H>(pattern: String, handler: H) -> ((String) -> (H?, Parameters)) {
        return { (route: String) -> (H?, Parameters) in
            let start: String! = "^\(pattern)/?$"
            
            let matchResults = { (string: String, regex: String) -> [NSTextCheckingResult]? in
                return (try? NSRegularExpression(pattern: regex, options: .CaseInsensitive))
                    .map { $0.matchesInString(string, options: [], range: NSMakeRange(0, string.characters.count)) }
            }
            
            let ranges = matchResults(start, ":[a-zA-Z0-9-_]+")?.map { $0.range }
            let dynamicSegments = ranges?.map { (start as NSString).substringWithRange($0) }
            let patterns = (regex: dynamicSegments?.reduce(start) { $0.stringByReplacingOccurrencesOfString($1, withString: "([^/]+)") },
                keys: dynamicSegments?.map { $0.stringByReplacingOccurrencesOfString(":", withString: "") })
            
            guard let m = patterns.regex.flatMap({ matchResults(route, $0)?.first }), let keys = patterns.keys where keys.count == m.numberOfRanges - 1 else {
                return (nil, [:])
            }
            
            let parameters = [Int](1 ..< m.numberOfRanges).reduce(Parameters()) { (var p, i) in
                p[keys[i-1]] = (route as NSString).substringWithRange(m.rangeAtIndex(i))
                return p
            }
            
            return (handler, parameters)
        }
    }
    
}
