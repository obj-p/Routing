//
//  Route.swift
//  Routing
//
//  Created by Jason Prasad on 6/17/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import Foundation

public typealias Parameters = [String: String]
public typealias RouteHandler = (String, Parameters, Completed) -> Void
public typealias Completed = () -> Void
public typealias ProxyHandler = (String, Parameters, Next) -> Void
public typealias Next = (String?, Parameters?) -> Void

internal struct Route {
    
    internal enum HandlerType {
        case Route(RouteHandler)
        case Proxy(ProxyHandler)
    }
    
    internal let pattern: String
    internal let handler: HandlerType
    internal let queue: dispatch_queue_t
    internal let isProxy: Bool
    private let dynamicSegments: [String]
    
    internal init(_ pattern: String, queue: dispatch_queue_t, handler: HandlerType) {
        var pattern = pattern
        var dynamicSegments = [String]()
        Route.prepare(&pattern, dynamicSegments: &dynamicSegments)
        
        self.pattern = pattern
        self.queue = queue
        self.handler = handler
        
        if case .Proxy(_) = handler {
            isProxy = true
        } else {
            isProxy = false
        }
        
        self.dynamicSegments = dynamicSegments
    }
    
    internal func matches(route: String) -> Bool {
        return _matches(route) != nil
    }
    
    internal func matches(route: String, inout parameters: Parameters) -> Bool {
        guard let matches = _matches(route) else {
            return false
        }
        
        if dynamicSegments.count > 0 && dynamicSegments.count == matches.count {
            for (segment, match) in zip(dynamicSegments, matches) {
                parameters[segment] = (route as NSString).substringWithRange(match.range)
            }
        }
        
        return true
    }
    
    private func _matches(route: String) -> [NSTextCheckingResult]? {
        return (try? NSRegularExpression(pattern: pattern, options: .CaseInsensitive))
            .flatMap {
                $0.matchesInString(route, options: [], range: NSMakeRange(0, route.characters.count))
            }
    }
    
    private static func prepare(inout pattern: String, inout dynamicSegments: [String]) {
        var pattern = pattern
        let options: NSStringCompareOptions = [.RegularExpressionSearch, .CaseInsensitiveSearch]
        while let range = pattern.rangeOfString(":[a-zA-Z0-9-_]+", options: options) {
            let segment = pattern
                .substringWithRange(range.startIndex.advancedBy(1)..<range.endIndex)
            dynamicSegments.append(segment)
            pattern.replaceRange(range, with: "([^/]+)")
        }
    }
    
}
