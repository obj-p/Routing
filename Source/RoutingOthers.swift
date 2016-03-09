//
//  RoutingOthers.swift
//  Routing
//
//  Created by Jason Prasad on 3/7/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import Foundation

public final class Routing: BaseRouting {
    
    public override init(){
        super.init()
    }
    
    /**
     Associates a closure to a string pattern. A Routing instance will execute the closure in the
     event of a matching URL using #open. Routing will only execute the first matching mapped route.
     This will be the last routed added with #map.
     
     ```code
     let router = Routing()
     router.map("routing://route") { parameters, completed in
     completed() // Must call completed or the router will halt!
     }
     ```
     
     - Parameter pattern:  A String pattern
     - Parameter queue:  A dispatch queue for the callback
     - Parameter handler:  A MapHandler
     */
    
    public override func map(pattern: String,
        queue: dispatch_queue_t = dispatch_get_main_queue(),
        handler: MapHandler) {
            super.map(pattern, queue: queue, handler: handler)
    }
    
    /**
     Associates a closure to a string pattern. A Routing instance will execute the closure in the
     event of a matching URL using #open. Routing will execute all proxies unless #next() is called
     with non nil arguments.
     
     ```code
     let router = Routing()
     router.proxy("routing://route") { route, parameters, next in
     next(route, parameters) // Must call next or the router will halt!
     /* alternatively, next(nil, nil) allowing additional proxies to execute */
     }
     ```
     
     - Parameter pattern:  A String pattern
     - Parameter queue:  A dispatch queue for the callback
     - Parameter handler:  A ProxyHandler
     */
    
    public override func proxy(pattern: String,
        queue: dispatch_queue_t = dispatch_get_main_queue(),
        handler: ProxyHandler) {
            super.proxy(pattern, queue: queue, handler: handler)
    }
    
    /**
     Will execute the first mapped closure and any proxies with matching patterns. Mapped closures
     are read in a last to be mapped first executed order.
     
     - Parameter string:  A string represeting a URL
     - Returns:  A Bool. True if the string is a valid URL and it can open the URL, false otherwise
     */
    
    public override func open(string: String) -> Bool {
        return super.open(string)
    }
    
    /**
     Will execute the first mapped closure and any proxies with matching patterns. Mapped closures
     are read in a last to be mapped first executed order.
     
     - Parameter URL:  A URL
     - Returns:  A Bool. True if it can open the URL, false otherwise
     */
    
    public override func open(URL: NSURL) -> Bool {
        return super.open(URL)
    }
}
