//
//  Routing.swift
//  Routing
//
//  Created by Jason Prasad on 9/28/15.
//  Copyright © 2015 Routing. All rights reserved.
//

import Foundation

public class Routing {
    public typealias RouteHandler = ([String : String]) -> Void
    public typealias RouteMatcher = (String) -> (RouteHandler?, [String : String])
    
    private var routes: [RouteMatcher] = [RouteMatcher]()
    
    public init() {}
    
    public func add(route: String, handler: RouteHandler) -> Void {
        let rm = { [weak self] (aRoute: String) -> (RouteHandler?, [String : String]) in
            let patterns = self?.patterns(route)
            
            let match = patterns?.regex
                .map { self?.matchResults(aRoute, regex: $0)?.first }?
                .flatMap { $0 }
            
            if let m = match, let keys = patterns?.keys {
                var parameters: [String : String] = [:]
                for i in 1 ..< m.numberOfRanges where keys.count == m.numberOfRanges - 1 {
                    parameters.updateValue((aRoute as NSString).substringWithRange(m.rangeAtIndex(i)), forKey: keys[i-1])
                }
                
                return (handler, parameters)
            }
            
            return (nil, [:])
        }
        
        self.routes.append(rm)
    }
    
    public func open(URL: NSURL) -> Bool {
        let components = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false)
        
        let route = components
            .map { "/" + ($0.host ?? "") + ($0.path ?? "") }
        
        let queryItems = components
            .map { $0.queryItems }??
            .reduce([String : String]()) { (var dict, item) in dict.updateValue((item.value ?? ""), forKey: item.name); return dict }
            ?? [:]
        
        return route
            .map { (route) -> [(RouteHandler?, [String : String])] in self.routes.map { $0(route) } }?
            .filter { $0.0 != nil }
            .map { (handler, var parameters) -> (RouteHandler, [String : String]) in
                for item in queryItems { parameters[item.0] = item.1 }
                handler!(parameters)
                return (handler!, parameters)
            }.isEmpty == false ?? false
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
