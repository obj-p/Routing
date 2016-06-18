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
    
    public init(){}
    
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
        guard let URL = NSURL(string: string) else {
            return false
        }
        
        return open(URL)
    }
    
    public func open(URL: NSURL) -> Bool {
        guard let components = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false) else {
            return false
        }
        
        var searchPath = String()
        var parameters = Parameters()
        Routing.prepare(&searchPath, queryParameters: &parameters, from: components)
        
        var currentRoutes: [Route]!
        var matchedRoute: Route!
        dispatch_sync(accessQueue) {
            currentRoutes = self.routes
            for route in currentRoutes
                where !route.isProxy && route.matches(searchPath, parameters: &parameters) {
                    matchedRoute = route
                    break
            }
        }
        
        if matchedRoute == nil {
            return false
        }
        
        defer {
            dispatch_async(routingQueue) {
                self.process(searchPath,
                             parameters: parameters,
                             matching: matchedRoute,
                             within: currentRoutes)
            }
        }
        
        return true
    }
    
    private func process(searchPath: String,
                         parameters: Parameters,
                         matching route: Route,
                                  within routes: [Route]) {
        let semaphore = dispatch_semaphore_create(0)
        var modifiedSearchPath: String?, modifiedParameters: Parameters?
        for proxy in routes where proxy.isProxy && proxy.matches(searchPath) {
            if case let .Proxy(handler) = proxy.handler {
                dispatch_async(proxy.queue) {
                    handler(searchPath, parameters) { (proxiedPath, proxiedParameters) in
                        modifiedSearchPath = proxiedPath
                        modifiedParameters = proxiedParameters
                        dispatch_semaphore_signal(semaphore)
                    }
                }
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
                if (modifiedSearchPath != nil || modifiedParameters != nil) {
                    break
                }
            }
        }
        
        var parameters = parameters
        if let modifiedParameters = modifiedParameters {
            modifiedParameters.forEach {
                parameters[$0.0] = $0.1
            }
        }
        
        var searchPath = searchPath
        var route = route
        if let modifiedSearchPath = modifiedSearchPath {
            searchPath = modifiedSearchPath
            for proxiedRoute in routes
                where !proxiedRoute.isProxy && proxiedRoute.matches(searchPath) {
                route = proxiedRoute
                    break
            }
        }
        
        dispatch_async(route.queue) {
            if case let .Route(handler) = route.handler {
                handler(searchPath, parameters) {
                    dispatch_semaphore_signal(semaphore)
                }
            }
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
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
        for route in routes where !route.isProxy && route.matches(matching) {
            return route
        }
        return nil
    }
    
}
