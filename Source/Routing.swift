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
    
    /**
     Associates a closure to a string pattern. A Routing instance will execute the closure in the
     event of a matching URL using #open. Routing will only execute the first matching mapped route.
     This will be the last route added with #map.
     
     ```code
     let router = Routing()
     router.map("routing://route") { parameters, completed in
        completed() // Must call completed or the router will halt!
     }
     ```
     
     - Parameter pattern:  A String pattern
     - Parameter queue:  A dispatch queue for the callback
     - Parameter tag:
     - Parameter handler:  A MapHandler
     */
    
    public func map(pattern: String,
                    tag: String = "",
                    queue: dispatch_queue_t = dispatch_get_main_queue(),
                    handler: RouteHandler) -> Void {
        dispatch_async(accessQueue) {
            self.routes.insert(Route(pattern, tag: tag, queue: queue, handler: .Route(handler)), atIndex: 0)
        }
    }
    
    /**
     Associates a closure to a string pattern. A Routing instance will execute the closure in the
     event of a matching URL using #open. Routing will execute all proxies unless #next() is called
     with non nil arguments.
     
     ```code
     let router = Routing()
     router.proxy("routing://route") { route, parameters, next in
        next(route, parameters) // Must call next or the router will halt!
        /* alternatively, next(nil, nil) allowing additional proxies to execute */
     }
     ```
     
     - Parameter pattern:  A String pattern
     - Parameter queue:  A dispatch queue for the callback
     - Parameter tag:
     - Parameter handler:  A ProxyHandler
     */
    
    public func proxy(pattern: String,
                      tag: String = "",
                      queue: dispatch_queue_t = dispatch_get_main_queue(),
                      handler: ProxyHandler) -> Void {
        dispatch_async(accessQueue) {
            self.routes.insert(Route(pattern, tag: tag, queue: queue, handler: .Proxy(handler)), atIndex: 0)
        }
    }
    
    /**
     Will execute the first mapped closure and any proxies with matching patterns. Mapped closures
     are read in a last to be mapped first executed order.
     
     - Parameter string:  A string represeting a URL
     - Returns:  A Bool. True if the string is a valid URL and it can open the URL, false otherwise
     */
    
    public func open(string: String) -> Bool {
        guard let URL = NSURL(string: string) else {
            return false
        }
        
        return open(URL)
    }
    
    /**
     Will execute the first mapped closure and any proxies with matching patterns. Mapped closures
     are read in a last to be mapped first executed order.
     
     - Parameter URL:  A URL
     - Returns:  A Bool. True if it can open the URL, false otherwise
     */
    
    public func open(URL: NSURL) -> Bool {
        guard let components = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false) else {
            return false
        }
        
        var parameters = Parameters()
        components.queryItems?.forEach {
            parameters[$0.name] = ($0.value ?? "")
        }
        components.query = nil
        var searchPath = components.string ?? ""
        
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
        var modifiedRoute: Route? = route
        if let modifiedSearchPath = modifiedSearchPath {
            searchPath = modifiedSearchPath
            modifiedRoute = nil
            for proxiedRoute in routes
                where !proxiedRoute.isProxy && proxiedRoute.matches(searchPath) {
                modifiedRoute = proxiedRoute
                    break
            }
        }
        
        guard let route = modifiedRoute else {
            return
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
}

public extension Routing {
    subscript(pattern: String) -> Routing {
        get {
            return self
        }
    }
}
