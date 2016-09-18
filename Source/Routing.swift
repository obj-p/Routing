//
//  Routing.swift
//  Routing
//
//  Created by Jason Prasad on 9/28/15.
//  Copyright © 2015 Routing. All rights reserved.
//

import Foundation

fileprivate struct RoutableWork {
    var routes: [Route] = [Route]()
    var proxies: [Proxy] = [Proxy]()
    var initialRoute: Route? = nil
    var searchPath: String = ""
    var parameters: Parameters = Parameters()
    var passedAny: Any? = nil
}

public final class Routing: RouteOwner {
    fileprivate var routes: [Route] = [Route]()
    fileprivate var proxies: [Proxy] = [Proxy]()
    fileprivate var accessQueue = DispatchQueue(label: "Routing Access Queue", attributes: [])
    fileprivate var routingQueue: DispatchQueue
    
    public subscript(tags: String...) -> Routing {
        get {
            let set = Set(tags)
            var sub: Routing!
            accessQueue.sync {
                sub = Routing(routes: self.routes.filter({ set.intersection($0.tags).isEmpty == false }),
                              proxies: self.proxies.filter({ set.intersection($0.tags).isEmpty == false }),
                              targetQueue: self.routingQueue)
            }
            return sub
        }
    }
    
    public init() {
        routingQueue = DispatchQueue(label: "Routing Queue", attributes: [])
    }
    
    fileprivate init(routes: [Route], proxies: [Proxy], targetQueue: DispatchQueue) {
        routingQueue = DispatchQueue(label: "Routing Queue", attributes: [], target: targetQueue)
        self.routes = routes
        self.proxies = proxies
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
        let proxy = Proxy(pattern, tags: tags, owner: owner ?? self, queue: queue, handler: handler)
        accessQueue.async {
            self.proxies.insert(proxy, at: 0)
        }
        return proxy.uuid
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
        var work = RoutableWork()
        guard let searchPath = searchPath(from: URL, with: &work.parameters) else {
            return false
        }
        work.searchPath = searchPath
        
        accessQueue.sync {
            routes = routes.filter { $0.owner != nil }
            proxies = proxies.filter { $0.owner != nil }
            work.routes = routes
            work.proxies = proxies
            for route in work.routes where self.searchPath(work.searchPath, matches: route, parameters: &work.parameters) {
                work.initialRoute = route
                break
            }
        }
        
        if work.initialRoute == nil {
            return false
        }
        
        work.passedAny = any
        defer {
            routingQueue.async {
                self.process(work: work)
            }
        }
        
        return true
    }
    
    /**
     Removes the route with the given RouteUUID.
     
     - Parameter route:  A RouteUUID
     */
    
    public func dispose(of uuid: RouteUUID) {
        accessQueue.async {
            self.routes = self.routes.filter { $0.uuid != uuid }
            self.proxies = self.proxies.filter { $0.uuid != uuid }
        }
    }
    
    fileprivate func process(work: RoutableWork) {
        let semaphore = DispatchSemaphore(value: 0)
        var proxyCommit: ProxyCommit?
        for proxy in work.proxies where searchPath(work.searchPath, matches: proxy) {
            proxy.queue.async {
                proxy.handler(work.searchPath, work.parameters, work.passedAny) { commit in
                    proxyCommit = commit
                    semaphore.signal()
                }
            }
            semaphore.wait()
            if proxyCommit != nil {
                break
            }
        }
        
        var work = work
        var proxiedRoute: Route?
        // TODO: Commit route confusing with Routable route
        if let proxied = proxyCommit?.route {
            work.searchPath = searchPath(from: proxied, with: &work.parameters) ?? ""
            proxiedRoute = nil
            for route in work.routes where searchPath(work.searchPath, matches: route) {
                proxiedRoute = route
                break
            }
        } else {
            proxiedRoute = work.initialRoute
        }
        
        guard let resultingRoute = proxiedRoute else {
            return
        }
        
        if let commit = proxyCommit {
            commit.parameters.forEach {
                work.parameters[$0.0] = $0.1
            }
            work.passedAny = commit.data
        }
        
        resultingRoute.queue.async {
            resultingRoute.handler(work.searchPath, work.parameters, work.passedAny) {
                semaphore.signal()
            }
        }
        semaphore.wait()
    }
    
    fileprivate func searchPath(from URL: URL, with parameters: inout Parameters) -> String? {
        guard var components = URLComponents(url: URL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        components.queryItems?.forEach {
            parameters[$0.name] = ($0.value ?? "")
        }
        components.query = nil
        
        return components.string
    }
    
    fileprivate func searchPath(from URLString: String, with parameters: inout Parameters) -> String? {
        return URL(string: URLString).flatMap { return searchPath(from: $0, with: &parameters) }
    }
    
    fileprivate func searchPath<T>(_ URLString: String, matches routable: Routable<T>) -> Bool {
        return _searchPath(URLString, matches: routable.pattern) != nil
    }
    
    fileprivate func searchPath<T>(_ URLString: String, matches routable: Routable<T>, parameters: inout Parameters) -> Bool {
        guard let matches = _searchPath(URLString, matches: routable.pattern) else {
            return false
        }
        
        if routable.dynamicSegments.count > 0 && routable.dynamicSegments.count == matches.numberOfRanges - 1 {
            for i in (1 ..< matches.numberOfRanges) {
                parameters[routable.dynamicSegments[i-1]] = (URLString as NSString)
                    .substring(with: matches.rangeAt(i))
            }
        }
        
        return true
    }
    
    fileprivate func _searchPath(_ URLString: String, matches pattern: String) -> NSTextCheckingResult? {
        return (try? NSRegularExpression(pattern: pattern, options: .caseInsensitive))
            .flatMap {
                $0.matches(in: URLString, options: [], range: NSMakeRange(0, URLString.characters.count))
            }?.first
    }
}
