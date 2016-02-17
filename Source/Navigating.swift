//
//  Navigating.swift
//  Routing
//
//  Created by Jason Prasad on 2/15/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import UIKit

public extension Routing {
    
    public enum PresentationStyle {
        case Root
        case Show
        case Present
        case Custom((presenting: UIViewController, presented: UIViewController, completed: Completed) -> Void)
    }
    
    public typealias NavigatingHandler = (Parameters) -> UIViewController
    
    public func map(pattern: String,
        queue: dispatch_queue_t = dispatch_get_main_queue(),
        controller: UIViewController.Type,
        style: PresentationStyle = .Show,
        contained: Bool = false,
        handler: NavigatingHandler) -> Void {
            dispatch_barrier_async(accessQueue) {
                self.maps.insert(self.prepareNavigator(pattern,
                    queue: queue,
                    controller: controller,
                    style: style,
                    contained: contained,
                    handler: handler), atIndex: 0)
            }
    }
    
    private func prepareNavigator(pattern: String,
        queue: dispatch_queue_t,
        controller: UIViewController.Type,
        style: PresentationStyle,
        contained: Bool,
        handler: NavigatingHandler) -> ((String) -> (dispatch_queue_t, MapHandler?, Parameters)) {
            updateNavigationTree(pattern, controller: controller, style: style, contained: contained)
            
            let mapHandler: MapHandler = { parameters, completed in
                // Retrieve Tree
                // Climb from root to current and reset root if needed
                // Call each NavigatingHandler block in tree path
            }
            
            return self.prepare(pattern, queue: queue, handler: mapHandler)
    }
    
    private func updateNavigationTree(pattern: String, controller: UIViewController.Type, style: PresentationStyle, contained: Bool) {
        // Update navigation structure
    }
    
}
