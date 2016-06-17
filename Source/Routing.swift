//
//  Routing.swift
//  Routing
//
//  Created by Jason Prasad on 9/28/15.
//  Copyright © 2015 Routing. All rights reserved.
//

import Foundation

public struct Route {
    
    public typealias Parameters = [String: String]
    public typealias RouteHandler = (String, Parameters, Completed) -> Void
    public typealias Completed = () -> Void
    public typealias ProxyHandler = (String, Parameters, Next) -> Void
    public typealias Next = (String?, Parameters?) -> Void
    
    private enum HandlerType {
        case Route(RouteHandler)
        case Proxy(ProxyHandler)
    }
    
    private let pattern: String
    private let dynamicSegments: [String]
    private let queue: dispatch_queue_t
    private let handler: HandlerType
    private var isProxy: Bool {
        if case HandlerType.Proxy(_) = handler {
            return true
        }
        return false
    }
    
    private init(_ pattern: String, queue: dispatch_queue_t, handler: HandlerType) {
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
        self.dynamicSegments = dynamicSegments
        self.queue = queue
        self.handler = handler
    }
    
    private func matches(route: String) -> NSTextCheckingResult? {
        return (try? NSRegularExpression(pattern: pattern, options: .CaseInsensitive))
            .flatMap {
                $0.matchesInString(route, options: [], range: NSMakeRange(0, route.characters.count))
            }?.first
    }
    
    private func parameters(route: String, matches: NSTextCheckingResult) -> Parameters {
        var parameters = Parameters()
        if dynamicSegments.count > 0 && dynamicSegments.count == matches.numberOfRanges - 1 {
            [Int](1 ..< matches.numberOfRanges).forEach { (index) in
                parameters[dynamicSegments[index-1]] = (route as NSString).substringWithRange(matches.rangeAtIndex(index))
            }
        }
        return parameters
    }
    
}

public final class Routing {
    
    private var routes: [Route] = [Route]()
    private var accessQueue = dispatch_queue_create("Routing Access Queue", DISPATCH_QUEUE_SERIAL)
    private var routingQueue = dispatch_queue_create("Routing Queue", DISPATCH_QUEUE_SERIAL)
    
    internal init(){}
    
    public func map(pattern: String,
                    queue: dispatch_queue_t = dispatch_get_main_queue(),
                    handler: Route.RouteHandler) -> Void {
        dispatch_async(accessQueue) {
            self.routes.insert(Route(pattern, queue: queue, handler: .Route(handler)), atIndex: 0)
        }
    }
    
    public func proxy(pattern: String,
                      queue: dispatch_queue_t = dispatch_get_main_queue(),
                      handler: Route.ProxyHandler) -> Void {
        dispatch_async(accessQueue) {
            self.routes.insert(Route(pattern, queue: queue, handler: .Proxy(handler)), atIndex: 0)
        }
    }
    
    public func open(string: String) -> Bool {
        guard let URL = NSURL(string: string) else {
            return false
        }
        
        return open(URL)
    }
    
    public func open(URL: NSURL) -> Bool {
        guard let components = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false) else {
            return false
        }
        
        var _routes: [Route]!
        var matchedRoute: Route!
        var matchedString: String!
        var parameters: Route.Parameters!
        dispatch_sync(accessQueue) {
            _routes = self.routes
            if _routes.count > 0 {
                var queryParameters: [String: String] = [:]
                components.queryItems?.forEach {
                    queryParameters.updateValue(($0.value ?? ""), forKey: $0.name)
                }
                components.query = nil
                var URLString = components.string ?? ""
                
                for route in _routes where !route.isProxy {
                    if let matches = route.matches(URLString) {
                        matchedRoute = route
                        matchedString = URLString
                        parameters = route.parameters(URLString, matches: matches)
                        queryParameters.forEach { parameters![$0.0] = $0.1 }
                        break
                    }
                }
            }
        }
        
        guard matchedRoute != nil else {
            return false
        }
        
        defer {
            dispatch_async(routingQueue) {
                let semaphore = dispatch_semaphore_create(0)
                var overwrittingRoute: String?, overwrittingParameters: Route.Parameters?
                
                for route in _routes where route.isProxy && route.matches(matchedString) != nil {
                    if case let .Proxy(handler) = route.handler {
                        dispatch_async(route.queue) {
                            handler(matchedString, parameters) { (route, params) in
                                matchedString = route
                                parameters = params
                                dispatch_semaphore_signal(semaphore)
                            }
                        }
                        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
                        if overwrittingRoute != nil || overwrittingParameters != nil {
                            break
                        }
                    }
                }
                
                for route in _routes where !route.isProxy && route.matches(matchedString) != nil {
                    dispatch_async(route.queue) {
                        if case let .Route(handler) = route.handler {
                            handler(matchedString, parameters) {
                                dispatch_semaphore_signal(semaphore)
                            }
                        }
                    }
                    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
                }
            }
        }
        return true
    }
    
}
