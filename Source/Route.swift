//
//  Route.swift
//  Routing
//
//  Created by Jason Prasad on 6/17/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import Foundation

public typealias Parameters = [String: String]

/**
 The closure type associated with #map
 
 - Parameter Parameters:  Any query parameters or dynamic segments found in the URL
 - Parameter Completed: Must be called for Routing to continue processing other routes with #open
 */

public typealias RouteHandler = (String, Parameters, Completed) -> Void
public typealias Completed = () -> Void

/**
 The closure type associated with #proxy
 
 - Parameter String:  The route being opened
 - Parameter Parameters:  Any query parameters or dynamic segments found in the URL
 - Parameter Next: Must be called for Routing to continue processing. Calling #Next with
 nil arguments will continue executing other matching proxies. Calling #Next with non nil
 arguments will continue to process the route.
 */

public typealias ProxyHandler = (String, Parameters, Next) -> Void
public typealias Next = (String?, Parameters?) -> Void

internal struct Route {
    internal enum HandlerType {
        case Route(RouteHandler)
        case Proxy(ProxyHandler)
    }
    
    internal let pattern: String
    internal let tags: [String]
    internal let queue: dispatch_queue_t
    internal let handler: HandlerType
    internal let isProxy: Bool
    private let dynamicSegments: [String]
    
    internal init(_ pattern: String, tags: [String], queue: dispatch_queue_t, handler: HandlerType) {
        var pattern = pattern
        var dynamicSegments = [String]()
        let options: NSStringCompareOptions = [.RegularExpressionSearch, .CaseInsensitiveSearch]
        while let range = pattern.rangeOfString(":[a-zA-Z0-9-_]+", options: options) {
            let segment = pattern
                .substringWithRange(range.startIndex.advancedBy(1)..<range.endIndex)
            dynamicSegments.append(segment)
            pattern.replaceRange(range, with: "([^/]+)")
        }
        
        self.pattern = pattern
        self.tags = tags
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
        
        if dynamicSegments.count > 0 && dynamicSegments.count == matches.numberOfRanges - 1 {
            for i in (1 ..< matches.numberOfRanges) {
                parameters[dynamicSegments[i-1]] = (route as NSString)
                    .substringWithRange(matches.rangeAtIndex(i))
            }
        }
        
        return true
    }
    
    private func _matches(route: String) -> NSTextCheckingResult? {
        return (try? NSRegularExpression(pattern: pattern, options: .CaseInsensitive))
            .flatMap {
                $0.matchesInString(route, options: [], range: NSMakeRange(0, route.characters.count))
            }?.first
    }
}
