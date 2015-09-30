//
//  Routing.swift
//  Routing
//
//  Created by Jason Prasad on 9/28/15.
//  Copyright © 2015 Routing. All rights reserved.
//

import Foundation

public struct Routing {
    public typealias RouteHandler = (parameters: [String : String]) -> Void
    public typealias RouteMatcher = (String) -> RouteHandler?
    public typealias VariableMatcher = (String) -> [String : String]?
    
    public var matchers: [(RouteMatcher, VariableMatcher)] = [(RouteMatcher, VariableMatcher)]()
    
    public init() {}
    
    public func route(matcher: String, handler: RouteHandler...) -> Void {
        
    }
    
    public func open(URL: NSURL) -> Bool {
        let route = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false)
            .map { "/" + ($0.host ?? "") + ($0.path ?? "") }
        
        if let matched = route.map({ (route) -> [(RouteHandler?, [String : String]?)] in self.matchers.map { ($0.0(route), $0.1(route)) } })?
            .filter({ $0.0 != nil }) {
                for case (let handler, let parameters) in matched { handler!(parameters: parameters ?? [:]); return true }
        }
        
        return false
    }
}


