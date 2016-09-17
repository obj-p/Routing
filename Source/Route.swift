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

/**
 The closure type associated with #map

 - Parameter Parameters:  Any query parameters or dynamic segments found in the URL
 - Parameter Data: Any data that could be passed with a routing
 - Parameter Completed: Must be called for Routing to continue processing other routes with #open
 */

public typealias RouteHandler = (String, Parameters, Any?, @escaping Completed) -> Void
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

public typealias ProxyHandler = (String, Parameters, Any?, @escaping Next) -> Void
public typealias ProxyCommit = (route: String, parameters: Parameters, data: Any?)
public typealias Next = (ProxyCommit?) -> Void

internal struct Route {
    internal enum HandlerType {
        case route(RouteHandler)
        case proxy(ProxyHandler)
    }

    internal let uuid = { UUID().uuidString }()
    internal let pattern: String
    internal let tags: [String]
    internal weak var owner: RouteOwner?
    internal let queue: DispatchQueue
    internal let handler: HandlerType
    fileprivate let dynamicSegments: [String]

    fileprivate init(_ pattern: String, tags: [String], owner: RouteOwner, queue: DispatchQueue, handler: HandlerType) {
        var pattern = pattern
        var dynamicSegments = [String]()
        let options: NSString.CompareOptions = [.regularExpression, .caseInsensitive]
        while let range = pattern.range(of: ":[a-zA-Z0-9-_]+", options: options) {
            let segment = pattern
                .substring(with: pattern.index(range.lowerBound, offsetBy: 1)..<range.upperBound)
            dynamicSegments.append(segment)
            pattern.replaceSubrange(range, with: "([^/]+)")
        }

        self.pattern = pattern
        self.tags = tags
        self.owner = owner
        self.queue = queue
        self.handler = handler
        self.dynamicSegments = dynamicSegments
    }

    internal init(_ pattern: String, tags: [String], owner: RouteOwner, queue: DispatchQueue, handler: @escaping RouteHandler) {
        self.init(pattern, tags: tags, owner: owner, queue: queue, handler: .route(handler))
    }

    internal init(_ pattern: String, tags: [String], owner: RouteOwner, queue: DispatchQueue, handler: @escaping ProxyHandler) {
        self.init(pattern, tags: tags, owner: owner, queue: queue, handler: .proxy(handler))
    }

    internal func matches(_ route: String) -> Bool {
        return _matches(route) != nil
    }

    internal func matches(_ route: String, parameters: inout Parameters) -> Bool {
        guard let matches = _matches(route) else {
            return false
        }

        if dynamicSegments.count > 0 && dynamicSegments.count == matches.numberOfRanges - 1 {
            for i in (1 ..< matches.numberOfRanges) {
                parameters[dynamicSegments[i-1]] = (route as NSString)
                    .substring(with: matches.rangeAt(i))
            }
        }

        return true
    }

    fileprivate func _matches(_ route: String) -> NSTextCheckingResult? {
        return (try? NSRegularExpression(pattern: pattern, options: .caseInsensitive))
            .flatMap {
                $0.matches(in: route, options: [], range: NSMakeRange(0, route.characters.count))
            }?.first
    }
}
