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
    
    public var matchers: [RouteMatcher] = [RouteMatcher]()
    
    public init() {}
    
    public func route(matcher: String, handler: RouteHandler) -> Void {
        let rm = { (string: String) -> (RouteHandler?, [String : String]?) in
            return (nil, nil)
        }
        
        self.matchers.append(rm)
    }
    
    public func open(URL: NSURL) -> Bool {
        let route = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false)
            .map { "/" + ($0.host ?? "") + ($0.path ?? "") }
        
        if let matched = route.map({ (route) -> [(RouteHandler?, [String : String]?)] in self.matchers.map { $0(route) } }) {
            for case (let handler, let parameters) in matched where handler != nil { handler!(parameters: parameters ?? [:]) }
            return true
        }
        
        return false
    }
    
    func matchers(string: String) -> (regex: String?, keys: [String]?) {
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


