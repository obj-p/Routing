//
//  Route.swift
//  Routing
//
//  Created by Jason Prasad on 6/17/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import Foundation

public protocol RouteOwner: class {}

public typealias RouteUUID = String

public typealias Parameters = [String: String]

public typealias Data = Any

/**
 The closure type associated with #map

 - Parameter Parameters:  Any query parameters or dynamic segments found in the URL
 - Parameter Data: Any data that could be passed with a routing
 - Parameter Completed: Must be called for Routing to continue processing other routes with #open
 */

public typealias RouteHandler = (String, Parameters, Data?, Completed) -> Void
public typealias Completed = () -> Void

/**
 The closure type associated with #proxy

 - Parameter String:  The route being opened
 - Parameter Parameters:  Any query parameters or dynamic segments found in the URL
 - Parameter Data: Any data that could be passed with a routing
 - Parameter Next: Must be called for Routing to continue processing. Calling #Next with
 nil arguments will continue executing other matching proxies. Calling #Next with non nil
 arguments will continue to process the route.
 */

public typealias ProxyHandler = (String, Parameters, Data?, Next) -> Void
public typealias Next = (String?, Parameters?, Data?) -> Void

internal struct Route {
    internal enum HandlerType {
        case Route(RouteHandler)
        case Proxy(ProxyHandler)
    }

    internal let uuid = { NSUUID().UUIDString }()
    internal let pattern: String
    internal let tags: [String]
    internal weak var owner: RouteOwner?
    internal let queue: dispatch_queue_t
    internal let handler: HandlerType
    private let dynamicSegments: [String]

    private init(_ pattern: String, tags: [String], owner: RouteOwner, queue: dispatch_queue_t, handler: HandlerType) {
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
        self.owner = owner
        self.queue = queue
        self.handler = handler
        self.dynamicSegments = dynamicSegments
    }

    internal init(_ pattern: String, tags: [String], owner: RouteOwner, queue: dispatch_queue_t, handler: RouteHandler) {
        self.init(pattern, tags: tags, owner: owner, queue: queue, handler: .Route(handler))
    }

    internal init(_ pattern: String, tags: [String], owner: RouteOwner, queue: dispatch_queue_t, handler: ProxyHandler) {
        self.init(pattern, tags: tags, owner: owner, queue: queue, handler: .Proxy(handler))
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
