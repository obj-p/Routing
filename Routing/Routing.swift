//
//  Routing.swift
//  Routing
//
//  Created by Jason Prasad on 9/28/15.
//  Copyright © 2015 Routing. All rights reserved.
//

import Foundation

public class Routing {
    public typealias RouteHandler = (parameters: [String : String]) -> Void
    public typealias RouteMatcher = (String) -> (RouteHandler?, [String : String]?)
    
    public var routes: [RouteMatcher] = [RouteMatcher]()
    
    public init() {}
    
    public func add(route: String, handler: RouteHandler) -> Void {
        let rm = { [weak self] (string: String) -> (RouteHandler?, [String : String]?) in
            let _ = self?.matchers(string)
            
            return (nil, nil)
        }
        
        self.routes.append(rm)
    }
    
    public func open(URL: NSURL) -> Bool {
        let route = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false)
            .map { "/" + ($0.host ?? "") + ($0.path ?? "") }
        
        if let matched = route.map({ (route) -> [(RouteHandler?, [String : String]?)] in self.routes.map { $0(route) } }) {
            for case (let handler, let parameters) in matched where handler != nil { handler!(parameters: parameters ?? [:]) }
            return true
        }
        
        return false
    }
    
    func matchers(route: String) -> (regex: String?, keys: [String]?) {
        var regex: String! = "^\(route)/?$"
        
        let ranges = (try? NSRegularExpression(pattern: ":[a-zA-Z0-9-_]+", options: .CaseInsensitive))
            .map { $0.matchesInString(regex, options: [], range: NSMakeRange(0, regex.characters.count)) }?
            .map { $0.range }
        
        let parameters = ranges?
            .map { (regex as NSString).substringWithRange($0) }
        
        let keys = parameters?
            .map { $0.stringByReplacingOccurrencesOfString(":", withString: "") }
        
        regex = parameters?
            .reduce(regex) { $0.stringByReplacingOccurrencesOfString($1, withString: "([^/]+)") }
        
        return (regex, keys)
    }
    
}


