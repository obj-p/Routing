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
    
    private enum RouteType {
        case Proxy((String) -> (ProxyHandler?, Parameters))
        case Route((String) -> (RouteHandler?, Parameters))
    }
    
    let accessQueue: dispatch_queue_t = dispatch_queue_create("Routing Access Queue", DISPATCH_QUEUE_CONCURRENT)
    let routingQueue: dispatch_queue_t = dispatch_queue_create("Routing Queue", DISPATCH_QUEUE_SERIAL)
    private var routes: [RouteType] = [RouteType]()
    
    public init() {}
    
    public func proxy(pattern: String, handler: ProxyHandler) -> Void {
        dispatch_barrier_async(accessQueue) {
            self.routes.insert(.Proxy(self.matcher(pattern, handler: handler)), atIndex: 0)
        }
    }
    
    public func map(pattern: String, handler: RouteHandler) -> Void {
        dispatch_barrier_async(accessQueue) {
            self.routes.insert(.Route(self.matcher(pattern, handler: handler)), atIndex: 0)
        }
    }
    
    public func open(URL: NSURL) -> Bool {
        var routes: [RouteType]!
        dispatch_sync(accessQueue) {
            routes = self.routes
        }
        
        if routes.count == 0 { return false }
        guard let components = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false) else {
            return false
        }
        
        var path = "/" + (components.host ?? "") + (components.path ?? "")
        
        var parameters: [String: String] = [:]
        components.queryItems?.forEach() {
            parameters.updateValue(($0.value ?? ""), forKey: $0.name)
        }
        
        let route = routes
            .map { closure -> (RouteHandler?, Parameters) in
                if case let .Route(f) = closure { return f(path) } // TODO: extract this common logic between Proxies and routes
                else { return (nil, [String: String]())}
            }
            .filter { $0.0 != nil }
            .first
        
        defer {
            dispatch_async(routingQueue) { [weak self] in
                let semaphore = dispatch_semaphore_create(0)
                
                routes // Proxies
                    .map { closure -> (ProxyHandler?, Parameters) in
                        if case let .Proxy(f) = closure { return f(path) }
                        else { return (nil, [String : String]())}
                    }
                    .filter { $0.0 != nil }
                    .forEach { (h, p) in
                        p.forEach { parameters[$0.0] = $0.1 }
                        dispatch_async(dispatch_get_main_queue()) {
                            h!(path, p) { (proxiedPath, proxiedParameters) in
                                (path, parameters) = (proxiedPath, proxiedParameters)
                                dispatch_semaphore_signal(semaphore)
                            }
                        }
                        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
                }

                let proxiedRoute = routes
                    .map { closure -> (RouteHandler?, Parameters) in
                        if case let .Route(f) = closure { return f(path) }
                        else { return (nil, [String: String]())}
                    }
                    .filter { $0.0 != nil }
                    .first
                
                _ = (proxiedRoute ?? route).map {
                    (h, p) -> (RouteHandler, Parameters) in
                    p.forEach { parameters[$0.0] = $0.1 } // TODO: This currrently overrides the proxied parameters
                    dispatch_async(dispatch_get_main_queue()) {
                        h!(parameters) {
                            dispatch_semaphore_signal(semaphore)
                        }
                    }
                    return (h!, p)
                }
            }
        }
        
        return route != nil
    }
    
    private func matcher<H>(route: String, handler: H) -> ((String) -> (H?, Parameters)) {
        return { [weak self] (aRoute: String) -> (H?, Parameters) in
            let patterns = self?.patterns(route)
            let match = patterns?.regex.flatMap { self?.matchResults(aRoute, regex: $0) }?.first
            
            guard let m = match, let keys = patterns?.keys where keys.count == m.numberOfRanges - 1 else {
                return (nil, [:])
            }
            
            let parameters = [Int](1 ..< m.numberOfRanges).reduce(Parameters()) { (var p, i) in
                p[keys[i-1]] = (aRoute as NSString).substringWithRange(m.rangeAtIndex(i))
                return p
            }
            
            return (handler, parameters)
        }
    }
    
    private func patterns(route: String) -> (regex: String?, keys: [String]?) {
        var regex: String! = "^\(route)/?$"
        let ranges = self.matchResults(regex, regex: ":[a-zA-Z0-9-_]+")?.map { $0.range }
        let parameters = ranges?.map { (regex as NSString).substringWithRange($0) }
        
        regex = parameters?.reduce(regex) { $0.stringByReplacingOccurrencesOfString($1, withString: "([^/]+)") }
        let keys = parameters?.map { $0.stringByReplacingOccurrencesOfString(":", withString: "") }
        
        return (regex, keys)
    }
    
    private func matchResults(string: String, regex: String) -> [NSTextCheckingResult]? {
        return (try? NSRegularExpression(pattern: regex, options: .CaseInsensitive))
            .map { $0.matchesInString(string, options: [], range: NSMakeRange(0, string.characters.count)) }
    }
    
}
