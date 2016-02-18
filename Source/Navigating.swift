//
//  Navigating.swift
//  Routing
//
//  Created by Jason Prasad on 2/15/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import UIKit

public enum PresentationStyle {
    case Root
    case Show
    case Present
    case Custom((presenting: UIViewController, presented: UIViewController, completed: Completed) -> Void)
}

public typealias NavigatingHandler = (Parameters) -> UIViewController

private indirect enum NavigatingNode {
    case Unknown(nodes: [String: NavigatingNode])
    case Known(controller: UIViewController.Type,
        style: PresentationStyle,
        contained: Bool,
        nodes: [String: NavigatingNode])
}

private var navigatingNodes: [String: NavigatingNode] = [:]

public final class Navigating: Routing {
    
    public func map(pattern: String,
        queue: dispatch_queue_t = dispatch_get_main_queue(),
        controller: UIViewController.Type,
        style: PresentationStyle = .Show,
        contained: Bool = false,
        handler: NavigatingHandler) -> Void {
            updateNavigationTree(pattern, controller: controller, style: style, contained: contained)
            
            let mapHandler: MapHandler = { parameters, completed in
                // Retrieve Tree
                // Climb from root to current and reset root if needed
                // Call each NavigatingHandler block in tree path
            }
       
            self.map(pattern, handler: mapHandler)
    }
    
    private func updateNavigationTree(pattern: String, controller: UIViewController.Type, style: PresentationStyle, contained: Bool) {
        // Update navigation structure
    }
    
}
