//
//  Routing.swift
//  Routing
//
//  Created by Jason Prasad on 9/28/15.
//  Copyright © 2015 Routing. All rights reserved.
//

import Foundation

public final class Routing: RouteOwner {
    private var routes: [Route] = [Route]()
    private var accessQueue = dispatch_queue_create("Routing Access Queue", DISPATCH_QUEUE_SERIAL)
    private var routingQueue = dispatch_queue_create("Routing Queue", DISPATCH_QUEUE_SERIAL)

    public subscript(tags: String...) -> Routing {
        get {
            let set = Set(tags)
            return Routing(routes: self.routes.filter({ set.intersect($0.tags).isEmpty == false }), targetQueue: self.routingQueue)
        }
    }

    public init() {}

    private convenience init(routes: [Route], targetQueue: dispatch_queue_t) {
        self.init()
        self.routes = routes
        dispatch_set_target_queue(self.routingQueue, targetQueue)
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

    public func map(pattern: String,
                    tags: [String] = [],
                    queue: dispatch_queue_t = dispatch_get_main_queue(),
                    owner: RouteOwner? = nil,
                    handler: RouteHandler) -> RouteUUID {
        let route = Route(pattern, tags: tags, owner: owner ?? self, queue: queue, handler: handler)
        dispatch_async(accessQueue) {
            self.routes.insert(route, atIndex: 0)
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

    public func proxy(pattern: String,
                      tags: [String] = [],
                      owner: RouteOwner? = nil,
                      queue: dispatch_queue_t = dispatch_get_main_queue(),
                      handler: ProxyHandler) -> RouteUUID {
        let route = Route(pattern, tags: tags, owner: owner ?? self, queue: queue, handler: handler)
        dispatch_async(accessQueue) {
            self.routes.insert(route, atIndex: 0)
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

    public func open(string: String, data: Data? = nil) -> Bool {
        guard let URL = NSURL(string: string) else {
            return false
        }

        return open(URL, data: data)
    }

    /**
     Will execute the first mapped closure and any proxies with matching patterns. Mapped closures
     are read in a last to be mapped first executed order.

     - Parameter URL:  A URL
     - Parameter data: Any data that will be passed with a routing
     - Returns:  A Bool. True if it can open the URL, false otherwise
     */

    public func open(URL: NSURL, data: Data? = nil) -> Bool {
        var parameters = Parameters()
        guard let searchPath = searchPath(URL, with: &parameters) else {
            return false
        }

        var currentRoutes: [Route]!
        var route: Route!
        dispatch_sync(accessQueue) {
            self.routes = self.routes.filter { $0.owner != nil }
            currentRoutes = self.routes
            let handlers = currentRoutes.map { $0.handler }
            for case let (matchedRoute, .Route(handler)) in zip(currentRoutes, handlers)
                where matchedRoute.matches(searchPath, parameters: &parameters) {
                    route = matchedRoute
                    break
            }
        }

        if route == nil {
            return false
        }

        defer {
            dispatch_async(routingQueue) {
                self.process(searchPath,
                             parameters: parameters,
                             data: data,
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

    public func disposeOf(route: RouteUUID) {
        dispatch_async(accessQueue) {
            self.routes = self.routes.filter { $0.uuid != route }
        }
    }

    private func process(searchPath: String,
                         parameters: Parameters,
                         data: Data,
                         matching route: Route,
                                  within routes: [Route]) {
        let semaphore = dispatch_semaphore_create(0)
        var newSearchPath: String?, newParameters: Parameters?, newData: Data?
        let zipped = zip(routes, routes.map { $0.handler })
        for case let (proxy, .Proxy(handler)) in zipped
            where proxy.matches(searchPath) {
                dispatch_async(proxy.queue) {
                    handler(searchPath, parameters, data) { (proxiedPath, proxiedParameters, proxiedData) in
                        newSearchPath = proxiedPath
                        newParameters = proxiedParameters
                        newData = proxiedData
                        dispatch_semaphore_signal(semaphore)
                    }
                }
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
                if (newSearchPath != nil || newParameters != nil || newData != nil) {
                    break
                }
        }

        var parameters = parameters
        if let newParameters = newParameters {
            newParameters.forEach {
                parameters[$0.0] = $0.1
            }
        }

        var searchPath = searchPath
        var newRoute: Route? = route
        if let newSearchPath = newSearchPath {
            searchPath = self.searchPath(newSearchPath, with: &parameters) ?? ""
            newRoute = nil
            for case let (proxiedRoute, .Route(_)) in zipped
                where proxiedRoute.matches(searchPath) {
                    newRoute = proxiedRoute
                    break
            }
        }

        guard let route = newRoute else {
            return
        }

        if case let .Route(handler) = route.handler {
            dispatch_async(route.queue) {
                handler(searchPath, parameters, data) {
                    dispatch_semaphore_signal(semaphore)
                }
            }
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }

    private func searchPath(URL: NSURL, inout with parameters: Parameters) -> String? {
        guard let components = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false) else {
            return nil
        }

        components.queryItems?.forEach {
            parameters[$0.name] = ($0.value ?? "")
        }
        components.query = nil

        return components.string
    }

    private func searchPath(URL: String, inout with parameters: Parameters) -> String? {
        return NSURL(string: URL).flatMap { return searchPath($0, with: &parameters) }
    }
}
