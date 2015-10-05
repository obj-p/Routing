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
    
    enum Matcher {
        case Proxy((String) -> (ProxyHandler?, Parameters))
        case Route((String) -> (RouteHandler?, Parameters))
    }
    
    private var matchers: [Matcher] = [Matcher]()
    
    private typealias ProxyMatcher = (String) -> (ProxyHandler?, Parameters)
    private var proxies: [ProxyMatcher] = [ProxyMatcher]()

    private typealias RouteMatcher = (String) -> (RouteHandler?, Parameters)
    private var routes: [RouteMatcher] = [RouteMatcher]()
    
    public init() {}

    public typealias ProxyHandler = (String, Parameters) -> (String, Parameters)
    public func proxy(route: String, handler: ProxyHandler) -> Void { self.proxies.append(self.matcher(route, handler: handler)) }

    public typealias RouteHandler = (Parameters) -> Void
    public func add(route: String, handler: RouteHandler) -> Void { self.routes.append(self.matcher(route, handler: handler)) }

    public func open(URL: NSURL) -> Bool {
        let components = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false)
        
        let route = components
            .map { "/" + ($0.host ?? "") + ($0.path ?? "") }
        
        let queryItems = components
            .flatMap { $0.queryItems }?
            .reduce(Parameters()) { (var dict, item) in dict.updateValue((item.value ?? ""), forKey: item.name); return dict }
            ?? [:]
        
        let proxy = route
            .map { (route) -> [(ProxyHandler?, Parameters)] in self.proxies.map { $0(route) } }?
            .filter { $0.0 != nil }
            .first
            .map { (handler, var parameters) -> (String, Parameters) in
                for item in queryItems { parameters[item.0] = item.1 }
                return handler!(route!, parameters)
            }
        
        return route
            .map { (route) -> [(RouteHandler?, Parameters)] in self.routes.map { $0(proxy?.0 ?? route) } }?
            .filter { $0.0 != nil }
            .first
            .map { (handler, var parameters) -> (RouteHandler, Parameters) in
                for item in queryItems where proxy?.1 == nil { parameters[item.0] = item.1 }
                handler!(proxy?.1 ?? parameters)
                return (handler!, proxy?.1 ?? parameters)
            } != nil
    }
    
    private func matcher<H>(route: String, handler: H) -> ((String) -> (H?, Parameters)) {
        return { [weak self] (aRoute: String) -> (H?, Parameters) in
            let patterns = self?.patterns(route)
            
            let match = patterns?.regex
                .flatMap { self?.matchResults(aRoute, regex: $0) }?
                .first
            
            var parameters: Parameters = [:]
            if let m = match, let keys = patterns?.keys {
                for i in 1 ..< m.numberOfRanges where keys.count == m.numberOfRanges - 1 {
                    parameters.updateValue((aRoute as NSString).substringWithRange(m.rangeAtIndex(i)), forKey: keys[i-1])
                }
                
                return (handler, parameters)
            }
            
            return (nil, parameters)
        }
    }
    
    private func patterns(route: String) -> (regex: String?, keys: [String]?) {
        var regex: String! = "^\(route)/?$"
        
        let ranges = self.matchResults(regex, regex: ":[a-zA-Z0-9-_]+")?
            .map { $0.range }
        
        let parameters = ranges?
            .map { (regex as NSString).substringWithRange($0) }
        
        let keys = parameters?
            .map { $0.stringByReplacingOccurrencesOfString(":", withString: "") }
        
        regex = parameters?
            .reduce(regex) { $0.stringByReplacingOccurrencesOfString($1, withString: "([^/]+)") }
        
        return (regex, keys)
    }
    
    private func matchResults(string: String, regex: String) -> [NSTextCheckingResult]? {
        return (try? NSRegularExpression(pattern: regex, options: .CaseInsensitive))
            .map { $0.matchesInString(string, options: [], range: NSMakeRange(0, string.characters.count)) }
    }
    
}
