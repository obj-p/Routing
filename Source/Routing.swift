//
//  Routing.swift
//  Routing
//
//  Created by Jason Prasad on 9/28/15.
//  Copyright © 2015 Routing. All rights reserved.
//

import Foundation

public final class Routing {
    
    private var routes: [Route] = [Route]()
    private var accessQueue = dispatch_queue_create("Routing Access Queue", DISPATCH_QUEUE_SERIAL)
    private var routingQueue = dispatch_queue_create("Routing Queue", DISPATCH_QUEUE_SERIAL)
    
    internal init(){}
    
    public func map(pattern: String,
                    queue: dispatch_queue_t = dispatch_get_main_queue(),
                    handler: RouteHandler) -> Void {
        dispatch_async(accessQueue) {
            self.routes.insert(Route(pattern, queue: queue, handler: .Route(handler)), atIndex: 0)
        }
    }
    
    public func proxy(pattern: String,
                      queue: dispatch_queue_t = dispatch_get_main_queue(),
                      handler: ProxyHandler) -> Void {
        dispatch_async(accessQueue) {
            self.routes.insert(Route(pattern, queue: queue, handler: .Proxy(handler)), atIndex: 0)
        }
    }
    
    public func open(string: String) -> Bool {
        guard let URL = NSURL(string: string) where routes.count > 0 else {
            return false
        }
        
        return open(URL)
    }
    
    public func open(URL: NSURL) -> Bool {
        guard let components = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false)
            where routes.count > 0 else {
                return false
        }
        
        var searchPath = String()
        var queryParameters: [String: String] = [:]
        Routing.prepare(&searchPath, queryParameters: &queryParameters, from: components)
        
        var currentRoutes: [Route]!
        dispatch_sync(accessQueue) {
            currentRoutes = self.routes
        }
        
        guard let matchedRoute = Routing.findRoute(searchPath, within: currentRoutes) else {
            return false
        }
        // Grab all Proxies
        // Cache results
        
        var _routes: [Route]!
        var matchedString: String!
        var parameters: Parameters!
        //        dispatch_sync(accessQueue) {
        //            _routes = self.routes
        //            if _routes.count > 0 {
        //
        //
        //
        //                for route in _routes where !route.isProxy {
        //                    if let matches = route.matches(URLString, parameters: []) {
        //                        matchedRoute = route
        //                        matchedString = URLString
        //                        parameters = route.parameters(URLString, matches: matches)
        //                        queryParameters.forEach { parameters![$0.0] = $0.1 }
        //                        break
        //                    }
        //                }
        //            }
        //        }
        
        defer {
            //            dispatch_async(routingQueue) {
            //                let semaphore = dispatch_semaphore_create(0)
            //                for route in _routes where route.isProxy && route.matches(matchedString) != nil {
            //                    if case let .Proxy(handler) = route.handler {
            //                        dispatch_async(route.queue) {
            //                            handler(matchedString, parameters) { (a, b) in
            //                                if let a = a, let b = b {
            //                                    matchedString = a
            //                                    parameters = b
            //                                }
            //                                dispatch_semaphore_signal(semaphore)
            //                            }
            //                        }
            //                        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            //                    }
            //                }
            //
            //                for route in _routes where !route.isProxy && route.matches(matchedString) != nil {
            //                    dispatch_async(route.queue) {
            //                        if case let .Route(handler) = route.handler {
            //                            handler(matchedString, parameters) {
            //                                dispatch_semaphore_signal(semaphore)
            //                            }
            //                        }
            //                    }
            //                    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            //                }
            //            }
        }
        return true
    }
    
    private static func prepare(inout searchPath: String,
                                      inout queryParameters: [String: String],
                                            from components: NSURLComponents) {
        components.queryItems?.forEach {
            queryParameters.updateValue(($0.value ?? ""), forKey: $0.name)
        }
        components.query = nil
        searchPath = components.string ?? ""
    }
    
    private static func findRoute(matching: String, within routes: [Route]) -> Route? {
        for route in routes where !route.isProxy {
            return route
        }
        return nil
    }
    
}
