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

public typealias NavigatingHandler = (Parameters) -> UIViewController

private indirect enum NavigatingNode {
    case Unknown(nodes: [String: NavigatingNode])
    case Known(controller: UIViewController.Type,
        style: PresentationStyle,
        contained: Bool,
        nodes: [String: NavigatingNode])
}

public final class Navigating: Routing {
    
    private var navigatingNodes: [String: NavigatingNode] = [:]
    private var nodesQueue = dispatch_queue_create("Navigating Nodes Queue", DISPATCH_QUEUE_CONCURRENT)
    
    public func map<T: UIViewController>(pattern: String,
        controller: T.Type,
        contained: Bool = false,
        style: PresentationStyle = .Show,
        storyboard: String,
        identifier: String,
        setup: (T, Parameters) -> Void) {
            let instance = { () -> T in
                let bundle = NSBundle(forClass: controller)
                let storyboard = UIStoryboard(name: storyboard, bundle: bundle)
                return storyboard.instantiateViewControllerWithIdentifier(identifier) as! T
            }
            map(pattern,
                controller: controller,
                contained: contained,
                style: style,
                instance: instance,
                setup: setup)
    }
    
    public func map<T: UIViewController>(pattern: String,
        controller: T.Type,
        contained: Bool = false,
        style: PresentationStyle = .Show,
        nib: String,
        bundle: String? = nil,
        setup: (T, Parameters) -> Void) {
            let instance = { () -> T in
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
    
    public func map<T: UIViewController>(pattern: String,
        controller: T.Type,
        contained: Bool = false,
        style: PresentationStyle = .Show,
        instance: () -> T,
        setup: (T, Parameters) -> Void) {
            updateNavigationTree(pattern,
                controller: controller,
                style: style,
                contained: contained,
                instance: instance,
                setup: setup)
            
            let mapHandler: MapHandler = { parameters, completed in
                // Retrieve Tree
                // Climb from root to current and reset root if needed
                // Call each NavigatingHandler block in tree path
            }
            
            self.map(pattern, handler: mapHandler)
    }
    
    private func updateNavigationTree<T: UIViewController>(var pattern: String,
        controller: T.Type,
        style: PresentationStyle,
        contained: Bool,
        instance: () -> T,
        setup: (T, Parameters) -> Void) {
            if let rangeOfScheme = pattern.rangeOfString("^(.*:)//", options: [.RegularExpressionSearch, .CaseInsensitiveSearch]) {
                pattern.replaceRange(rangeOfScheme, with: "")
            }
            
            var unknown = pattern.componentsSeparatedByString("/")
            let known = unknown.popLast()
    }
    
}
