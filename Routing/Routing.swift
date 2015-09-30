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
    public typealias RouteMatcher = (String) -> RouteHandler?
    public typealias ParameterMatcher = (String) -> [String : String]?
    
    public var matchers: [(RouteMatcher, ParameterMatcher)] = [(RouteMatcher, ParameterMatcher)]()
    
    public init() {}
    
    public func route(matcher: String, handler: RouteHandler) -> Void {
        let _ = regex(matcher)
        
        let rm = { (string: String) -> RouteHandler? in return nil }
        let pm = { (string: String) -> [String : String]? in return nil }
        self.matchers.append((rm, pm))
    }
    
    public func open(URL: NSURL) -> Bool {
        let route = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false)
            .map { "/" + ($0.host ?? "") + ($0.path ?? "") }
        
        if let matched = route.map({ (route) -> [(RouteHandler?, [String : String]?)] in self.matchers.map { ($0.0(route), $0.1(route)) } }) {
            for case (let handler, let parameters) in matched where handler != nil { handler!(parameters: parameters ?? [:]) }
            return true
        }
        
        return false
    }
    
    func regex(string: String) -> String? { return nil }
}


