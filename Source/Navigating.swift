//
//  Navigating.swift
//  Routing
//
//  Created by Jason Prasad on 2/15/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import UIKit

public enum PresentationStyle {
    case Show
    case Present(animated: () -> Bool)
    case Push(animated: () -> Bool)
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

public final class Navigating: Routing {
    
    public let rootViewController: UIViewController
    private var navigatingNodes: [String: NavigatingNode] = [:]
    private var nodesQueue = dispatch_queue_create("Navigating Nodes Queue", DISPATCH_QUEUE_CONCURRENT)
    
    public init(rootViewController: UIViewController) {
        self.rootViewController = rootViewController
        super.init()
    }
    
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
    
    private func updateNavigationTree(var pattern: String, controller: UIViewController.Type, style: PresentationStyle, contained: Bool) {
        if let rangeOfScheme = pattern.rangeOfString("^(.*:)//", options: [.RegularExpressionSearch, .CaseInsensitiveSearch]) {
            pattern.replaceRange(rangeOfScheme, with: "")
        }
        
        var unknown = pattern.componentsSeparatedByString("/")
        let known = unknown.popLast()
    }
    
}
