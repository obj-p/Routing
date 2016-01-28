//
//  Routing.swift
//  Routing
//
//  Created by Jason Prasad on 9/28/15.
//  Copyright © 2015 Routing. All rights reserved.
//

import Foundation

public class Routing {
    public typealias Parameters = [String : String]
    public typealias Completed = () -> Void
    
    public typealias ProxyHandler = (String, Parameters) -> (String, Parameters)
    public typealias RouteHandler = (Parameters, Completed) -> Void
    
    enum RouteType {
        case Proxy((String) -> (ProxyHandler?, Parameters))
        case Route((String) -> (RouteHandler?, Parameters))
    }
    
    let queue: dispatch_queue_t = dispatch_queue_create("Routing Queue", nil)
    private var routes: [RouteType] = [RouteType]()
    
    public init() {}
    
    // TODO: make these write operatious barrier asyncs to prevent an open URL from executing while updating routes.
    public func proxy(pattern: String, handler: ProxyHandler) -> Void { self.routes.append(.Proxy(self.matcher(pattern, handler: handler))) }
    public func map(pattern: String, handler: RouteHandler) -> Void { self.routes.append(.Route(self.matcher(pattern, handler: handler))) }
    
    let semaphore = dispatch_semaphore_create(1)
    public func open(URL: NSURL) -> Bool {
        let components = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false)
        
        guard let path = components.map({ "/" + ($0.host ?? "") + ($0.path ?? "") }) else {
            return false
        }
        
        let queryItems = components
            .flatMap { $0.queryItems }?
            .reduce(Parameters()) { (var dict, item) in dict.updateValue((item.value ?? ""), forKey: item.name); return dict }
            ?? [:]
        
        let proxy = self.routes
            .map { closure -> (ProxyHandler?, Parameters) in
                if case let .Proxy(f) = closure { return f(path) }
                else { return (nil, [String : String]())}
            }
            .filter { $0.0 != nil }
            .first
            .map { (handler, var parameters) -> (String, Parameters) in
                for item in queryItems { parameters[item.0] = item.1 }
                return handler!(path, parameters)
        }
        
        let route = self.routes
            .map { closure -> (RouteHandler?, Parameters) in
                if case let .Route(f) = closure { return f(proxy?.0 ?? path) }
                else { return (nil, [String : String]())}
            }
            .filter { $0.0 != nil }
            .first
        
        dispatch_async(queue) { [weak self] in
            if dispatch_semaphore_wait(self!.semaphore, DISPATCH_TIME_FOREVER) == 0 {
                _ = route.map { (handler, var parameters) -> (RouteHandler, Parameters) in
                    for item in queryItems where proxy?.1 == nil { parameters[item.0] = item.1 }
                    dispatch_async(dispatch_get_main_queue()) {
                        handler!(proxy?.1 ?? parameters) {
                            dispatch_semaphore_signal(self!.semaphore)
                        }
                    }
                    return (handler!, proxy?.1 ?? parameters)
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
