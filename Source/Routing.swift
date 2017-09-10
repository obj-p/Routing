import Foundation

fileprivate struct RoutableWork {
    var routes: [Route] = [Route]()
    var proxies: [Proxy] = [Proxy]()
    var initialRoutable: Route? = nil
    var searchRoute: String = ""
    var parameters: Parameters = Parameters()
    var passedAny: Any? = nil
}

public final class Routing: RouteOwner {
    private var routes: [Route] = [Route]()
    private var proxies: [Proxy] = [Proxy]()
    private var accessQueue: DispatchQueue
    private var openQueue: DispatchQueue
    private var processQueue: DispatchQueue
    
    public subscript(tags: String...) -> Routing {
        get {
            let set = Set(tags)
            var sub: Routing!
            accessQueue.sync {
                sub = Routing(routes: self.routes.filter({ set.intersection($0.tags).isEmpty == false }),
                              proxies: self.proxies.filter({ set.intersection($0.tags).isEmpty == false }),
                              accessQueue: self.accessQueue,
                              openQueue: self.openQueue,
                              processingQueue: self.processQueue)
            }
            
            return sub
        }
    }
    
    public init() {
        accessQueue = DispatchQueue(label: "Routing Access Queue", attributes: [])
        openQueue = DispatchQueue(label: "Routing Open Queue", attributes: [])
        processQueue = DispatchQueue(label: "Routing Process Queue", attributes: [])
    }
    
    private init(routes: [Route],
                 proxies: [Proxy],
                 accessQueue: DispatchQueue,
                 openQueue: DispatchQueue,
                 processingQueue: DispatchQueue) {
        self.accessQueue = accessQueue
        self.openQueue = openQueue
        self.processQueue = processingQueue
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
     - Parameter passing: Any data that will be passed with a routing
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
     - Parameter passing: Any data that will be passed with a routing
     - Returns:  A Bool. True if it can open the URL, false otherwise
     */
    
    @discardableResult
    public func open(_ URL: Foundation.URL, passing any: Any? = nil) -> Bool {
        var result = true
        
        openQueue.sync {
            var work = RoutableWork()
            guard let searchRoute = searchRoute(from: URL, with: &work.parameters) else {
                result = false
                return
            }
            work.searchRoute = searchRoute
            
            accessQueue.sync {
                routes = routes.filter { $0.owner != nil }
                proxies = proxies.filter { $0.owner != nil }
                work.routes = routes
                work.proxies = proxies
                for route in work.routes where self.searchRoute(work.searchRoute, matches: route, updating: &work.parameters) {
                    work.initialRoutable = route
                    break
                }
            }
            
            if work.initialRoutable == nil {
                result = false
            }
            
            work.passedAny = any
            self.process(work: work)
        }
        
        return result
    }
    
    /**
     Removes the route with the given RouteUUID.
     
     - Parameter of:  A RouteUUID
     */
    
    public func dispose(of uuid: RouteUUID) {
        accessQueue.async {
            self.routes = self.routes.filter { $0.uuid != uuid }
            self.proxies = self.proxies.filter { $0.uuid != uuid }
        }
    }
    
    private func process(work: RoutableWork) {
        processQueue.async {
            let semaphore = DispatchSemaphore(value: 0)
            var proxyCommit: ProxyCommit?
            for proxy in work.proxies where self.searchRoute(work.searchRoute, matches: proxy) {
                proxy.queue.async {
                    proxy.handler(work.searchRoute, work.parameters, work.passedAny) { commit in
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
            var resultingRoutable: Route?
            if let commit = proxyCommit {
                work.searchRoute = self.searchRoute(from: commit.route, updating: &work.parameters) ?? ""
                resultingRoutable = nil
                for route in work.routes where self.searchRoute(work.searchRoute, matches: route) {
                    resultingRoutable = route
                    break
                }
                
                commit.parameters.forEach {
                    work.parameters[$0.0] = $0.1
                }
                work.passedAny = commit.data
            } else {
                resultingRoutable = work.initialRoutable
            }
            
            if let resultingRoute = resultingRoutable {
                resultingRoute.queue.async {
                    resultingRoute.handler(work.searchRoute, work.parameters, work.passedAny) {
                        semaphore.signal()
                    }
                }
                semaphore.wait()
            }
        }
    }
    
    private func searchRoute(from URL: URL, with parameters: inout Parameters) -> String? {
        guard var components = URLComponents(url: URL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        components.queryItems?.forEach {
            parameters[$0.name] = ($0.value ?? "")
        }
        components.query = nil
        
        return components.string
    }
    
    private func searchRoute(from URLString: String, updating parameters: inout Parameters) -> String? {
        return URL(string: URLString).flatMap { return searchRoute(from: $0, with: &parameters) }
    }
    
    private func searchRoute<T>(_ URLString: String, matches routable: Routable<T>) -> Bool {
        return _searchRoute(URLString, matches: routable.pattern) != nil
    }
    
    private func searchRoute<T>(_ URLString: String, matches routable: Routable<T>, updating parameters: inout Parameters) -> Bool {
        guard let matches = _searchRoute(URLString, matches: routable.pattern) else {
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
    
    private func _searchRoute(_ URLString: String, matches pattern: String) -> NSTextCheckingResult? {
        return (try? NSRegularExpression(pattern: pattern, options: .caseInsensitive))
            .flatMap {
                $0.matches(in: URLString, options: [], range: NSMakeRange(0, URLString.characters.count))
            }?.first
    }
}
