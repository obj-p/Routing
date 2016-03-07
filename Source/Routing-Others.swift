//
//  Routing-Others.swift
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
    
    public override func map(pattern: String,
        queue: dispatch_queue_t = dispatch_get_main_queue(),
        handler: MapHandler) {
            super.map(pattern, queue: queue, handler: handler)
    }
    
    public override func proxy(pattern: String,
        queue: dispatch_queue_t = dispatch_get_main_queue(),
        handler: ProxyHandler) {
            super.proxy(pattern, queue: queue, handler: handler)
    }
    
    public override func open(URL: NSURL) -> Bool {
        return super.open(URL)
    }
}
