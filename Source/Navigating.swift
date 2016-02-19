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
    case ShowDetail
    case Present(animated: () -> Bool)
    case Push(animated: () -> Bool)
    case Custom((presenting: UIViewController,
        presented: UIViewController,
        completed: Completed) -> Void)
    
}

private struct NavigatingNode {
    
    let controller: UIViewController.Type
    let style: PresentationStyle
    let contained: Bool
    let instance: () -> UIViewController
    let setup: (UIViewController, Parameters) -> Void
    
    init(controller:UIViewController.Type,
        style: PresentationStyle,
        contained: Bool,
        instance: () -> UIViewController,
        setup: (UIViewController, Parameters) -> Void) {
            self.controller = controller
            self.style = style
            self.contained = contained
            self.instance = instance
            self.setup = setup
    }
    
}

public final class Navigating: Routing {
    
    private var navigatingNodes: [String: NavigatingNode] = [String: NavigatingNode]()
    private var nodesQueue = dispatch_queue_create("Navigating Nodes Queue", DISPATCH_QUEUE_CONCURRENT)
    
    public func map(pattern: String,
        controller: UIViewController.Type,
        contained: Bool = false,
        style: PresentationStyle = .Show,
        storyboard: String,
        identifier: String,
        setup: (UIViewController, Parameters) -> Void) {
            let instance = { () -> UIViewController in
                let bundle = NSBundle(forClass: controller)
                let storyboard = UIStoryboard(name: storyboard, bundle: bundle)
                return storyboard.instantiateViewControllerWithIdentifier(identifier)
            }
            map(pattern,
                controller: controller,
                contained: contained,
                style: style,
                instance: instance,
                setup: setup)
    }
    
    public func map(pattern: String,
        controller: UIViewController.Type,
        contained: Bool = false,
        style: PresentationStyle = .Show,
        nib: String,
        bundle: String? = nil,
        setup: (UIViewController, Parameters) -> Void) {
            let instance = { () -> UIViewController in
                let bundle = bundle.flatMap { NSBundle(identifier: $0) }
                    ?? NSBundle(forClass: controller)
                return controller.init(nibName: nib, bundle: bundle)
            }
            map(pattern,
                controller: controller,
                contained: contained,
                style: style,
                instance: instance,
                setup: setup)
    }
    
    public func map(pattern: String,
        controller: UIViewController.Type,
        contained: Bool = false,
        style: PresentationStyle = .Show,
        instance: () -> UIViewController,
        setup: (UIViewController, Parameters) -> Void) {
            updateNavigatingNodes(pattern,
                controller: controller,
                style: style,
                contained: contained,
                instance: instance,
                setup: setup)
            
            let mapHandler: MapHandler = { parameters, completed in
                print(self.navigatingNodes)
                // Retrieve nodes
                // Climb and inspect view hierarchy from root to current VC
                // Call each NavigatingNode needed to reach requested path
                completed()
            }
            
            self.map(pattern, handler: mapHandler)
    }
    
    private func updateNavigatingNodes(var pattern: String,
        controller: UIViewController.Type,
        style: PresentationStyle,
        contained: Bool,
        instance: () -> UIViewController,
        setup: (UIViewController, Parameters) -> Void) {
            dispatch_barrier_async(nodesQueue) {
                if let rangeOfScheme = pattern.rangeOfString("^(.*:)//", options: [.RegularExpressionSearch, .CaseInsensitiveSearch]) {
                    pattern.replaceRange(rangeOfScheme, with: "")
                }
                
                self.navigatingNodes[pattern] = NavigatingNode(controller: controller,
                    style: style,
                    contained: contained,
                    instance: instance,
                    setup: setup)
            }
    }
    
}
