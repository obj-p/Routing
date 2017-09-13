import Foundation

public protocol RouteOwner: class {}
public typealias RouteUUID = String
public typealias Parameters = [String: String]

/**
 The closure type associated with #map
 
 - Parameter Parameters:  Any query parameters or dynamic segments found in the URL
 - Parameter Any: Any data that could be passed with a routing
 - Parameter Completed: Must be called for Routing to continue processing other routes with #open
 */

public typealias RouteHandler = (String, Parameters, Any?, @escaping Completion) -> Void
public typealias Completion = () -> ()

/**
 The closure type associated with #proxy
 
 - Parameter String:  The route being opened
 - Parameter Parameters:  Any query parameters or dynamic segments found in the URL
 - Parameter Any: Any data that could be passed with a routing
 - Parameter Next: Must be called for Routing to continue processing. Calling #Next with
 nil arguments will continue executing other matching proxies. Calling #Next with non nil
 arguments will continue to process the route.
 */

public typealias ProxyHandler = (String, Parameters, Any?, @escaping Next) -> Void
public typealias ProxyCommit = (route: String, parameters: Parameters, data: Any?)
public typealias Next = (ProxyCommit?) -> Void

typealias Route = Routable<RouteHandler>
typealias Proxy = Routable<ProxyHandler>

struct Routable<T> {
    let uuid = { UUID().uuidString }()
    let pattern: String
    let tags: [String]
    weak var owner: RouteOwner?
    let queue: DispatchQueue
    let handler: T
    let dynamicSegments: [String]
    
    init(_ pattern: String, tags: [String], owner: RouteOwner, queue: DispatchQueue, handler: T) {
        var pattern = pattern
        var dynamicSegments = [String]()
        let options: NSString.CompareOptions = [.regularExpression, .caseInsensitive]
        while let range = pattern.range(of: ":[a-zA-Z0-9-_]+", options: options) {
            let segment = pattern[pattern.index(range.lowerBound, offsetBy: 1)..<range.upperBound]
            dynamicSegments.append(String(segment))
            pattern.replaceSubrange(range, with: "([^/]+)")
        }
        
        self.pattern = pattern
        self.tags = tags
        self.owner = owner
        self.queue = queue
        self.handler = handler
        self.dynamicSegments = dynamicSegments
    }
}
