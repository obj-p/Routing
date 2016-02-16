//
//  Navigating.swift
//  Routing
//
//  Created by Jason Prasad on 2/15/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import UIKit

public extension Routing {
    
    public typealias NavigateHandler = (Parameters, UIViewController, Completed) -> Void
    
    public func navigate(pattern: String, queue: dispatch_queue_t = dispatch_get_main_queue(), controller: UIViewController.Type, handler: NavigateHandler) -> Void {
        dispatch_barrier_async(accessQueue) {
            self.maps.insert(self.prepareNavigator(pattern, queue: queue, handler: handler), atIndex: 0)
        }
    }
    
    internal func prepareNavigator(pattern: String, queue: dispatch_queue_t, handler: NavigateHandler) -> ((String) -> (dispatch_queue_t, MapHandler?, Parameters)) {
        return self.prepare(pattern, queue: queue) { _, _ in }
    }
    
}
