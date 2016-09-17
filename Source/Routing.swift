//
//  Routing.swift
//  Routing
//
//  Created by Jason Prasad on 9/28/15.
//  Copyright © 2015 Routing. All rights reserved.
//

import Foundation

public final class Routing: RouteOwner {
    fileprivate var routes: [Route] = [Route]()
    fileprivate var accessQueue = DispatchQueue(label: "Routing Access Queue", attributes: [])
    fileprivate var routingQueue: DispatchQueue
    
    public subscript(tags: String...) -> Routing {
        get {
            let set = Set(tags)
            return Routing(routes: self.routes.filter({ set.intersection($0.tags).isEmpty == false }), targetQueue: self.routingQueue)
        }
    }
    
    public init() {
        routingQueue = DispatchQueue(label: "Routing Queue", attributes: [])
    }
    
    fileprivate init(routes: [Route], targetQueue: DispatchQueue) {
        routingQueue = DispatchQueue(label: "Routing Queue", attributes: [], target: targetQueue)
        self.routes = routes
    }
    
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
     - Parameter tag:  A tag to reference when subscripting a Routing object
     - Parameter owner: The routes owner. If deallocated the route will be removed.
     - Parameter queue:  A dispatch queue for the callback
     - Parameter handler:  A MapHandler
     - Returns:  The RouteUUID
     */
    
    @discardableResult
    public func map(_ pattern: String,
                    tags: [String] = [],
                    queue: DispatchQueue = DispatchQueue.main,
                    owner: RouteOwner? = nil,
                    handler: @escaping RouteHandler) -> RouteUUID {
        let route = Route(pattern, tags: tags, owner: owner ?? self, queue: queue, handler: handler)
        accessQueue.async {
            self.routes.insert(route, at: 0)
        }
        return route.uuid
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
     - Parameter tag:  A tag to reference when subscripting a Routing object
     - Parameter owner: The routes owner. If deallocated the route will be removed.
     - Parameter queue:  A dispatch queue for the callback
     - Parameter handler:  A ProxyHandler
     - Returns:  The RouteUUID
     */
    
    @discardableResult
    public func proxy(_ pattern: String,
                      tags: [String] = [],
                      owner: RouteOwner? = nil,
                      queue: DispatchQueue = DispatchQueue.main,
                      handler: @escaping ProxyHandler) -> RouteUUID {
        let route = Route(pattern, tags: tags, owner: owner ?? self, queue: queue, handler: handler)
        accessQueue.async {
            self.routes.insert(route, at: 0)
        }
        return route.uuid
    }
    
    /**
     Will execute the first mapped closure and any proxies with matching patterns. Mapped closures
     are read in a last to be mapped first executed order.
     
     - Parameter string:  A string represeting a URL
     - Parameter data: Any data that will be passed with a routing
     - Returns:  A Bool. True if the string is a valid URL and it can open the URL, false otherwise
     */
    
    @discardableResult
    public func open(_ string: String, passing any: Any? = nil) -> Bool {
        guard let URL = URL(string: string) else {
            return false
        }
        
        return open(URL, passing: any)
    }
    
    /**
     Will execute the first mapped closure and any proxies with matching patterns. Mapped closures
     are read in a last to be mapped first executed order.
     
     - Parameter URL:  A URL
     - Parameter data: Any data that will be passed with a routing
     - Returns:  A Bool. True if it can open the URL, false otherwise
     */
    
    @discardableResult
    public func open(_ URL: Foundation.URL, passing any: Any? = nil) -> Bool {
        var parameters = Parameters()
        guard let searchPath = searchPath(URL, with: &parameters) else {
            return false
        }
        
        var currentRoutes: [Route]!
        var route: Route!
        accessQueue.sync {
            self.routes = self.routes.filter { $0.owner != nil }
            currentRoutes = self.routes
            let handlers = currentRoutes.map { $0.handler }
            for case let (matchedRoute, .route(handler)) in zip(currentRoutes, handlers)
                where matchedRoute.matches(searchPath, parameters: &parameters) {
                    route = matchedRoute
                    break
            }
        }
        
        if route == nil {
            return false
        }
        
        defer {
            routingQueue.async {
                self.process(searchPath,
                             parameters: parameters,
                             any: any,
                             matching: route,
                             within: currentRoutes)
            }
        }
        
        return true
    }
    
    /**
     Removes the route with the given RouteUUID.
     
     - Parameter route:  A RouteUUID
     */
    
    public func disposeOf(_ route: RouteUUID) {
        accessQueue.async {
            self.routes = self.routes.filter { $0.uuid != route }
        }
    }
    
    fileprivate func process(_ searchPath: String,
                             parameters: Parameters,
                             any: Any?,
                             matching route: Route,
                             within routes: [Route]) {
        let semaphore = DispatchSemaphore(value: 0)
        var proxyCommit: ProxyCommit?
        let zipped = zip(routes, routes.map { $0.handler })
        for case let (proxy, .proxy(handler)) in zipped
            where proxy.matches(searchPath) {
                proxy.queue.async {
                    handler(searchPath, parameters, any) { commit in
                        proxyCommit = commit
                        semaphore.signal()
                    }
                }
                _ = semaphore.wait(timeout: DispatchTime.distantFuture)
                if proxyCommit != nil {
                    break
                }
        }
        
        var parameters = parameters
        if let newParameters = proxyCommit?.parameters {
            newParameters.forEach {
                parameters[$0.0] = $0.1
            }
        }
        
        var searchPath = searchPath
        var newRoute: Route? = route
        if let newSearchPath = proxyCommit?.route {
            searchPath = self.searchPath(newSearchPath, with: &parameters) ?? ""
            newRoute = nil
            for case let (proxiedRoute, .route(_)) in zipped
                where proxiedRoute.matches(searchPath) {
                    newRoute = proxiedRoute
                    break
            }
        }
        
        guard let route = newRoute else {
            return
        }
        
        var any = any
        if let newAny = proxyCommit?.data {
            any = newAny
        }
        
        if case let .route(handler) = route.handler {
            route.queue.async {
                handler(searchPath, parameters, any) {
                    semaphore.signal()
                }
            }
        }
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }
    
    fileprivate func searchPath(_ URL: Foundation.URL, with parameters: inout Parameters) -> String? {
        guard var components = URLComponents(url: URL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        components.queryItems?.forEach {
            parameters[$0.name] = ($0.value ?? "")
        }
        components.query = nil
        
        return components.string
    }
    
    fileprivate func searchPath(_ URL: String, with parameters: inout Parameters) -> String? {
        return Foundation.URL(string: URL).flatMap { return searchPath($0, with: &parameters) }
    }
}
