//
//  RoutingiOS.swift
//  Routing
//
//  Created by Jason Prasad on 2/15/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import UIKit

public enum PresentationStyle {
    
    case Show
    case ShowDetail
    case Present(animated: () -> Bool)
    case Push(animated: () -> Bool)
    case Custom(custom: (presenting: UIViewController,
        presented: UIViewController,
        completed: Completed) -> Void)
    
}

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
    
    public func map(pattern: String,
        storyboard: String,
        identifier: String,
        bundle: String? = nil,
        controller: UIViewController.Type = UIViewController.self,
        contained: Bool = false,
        style: PresentationStyle = .Show,
        setup: ((UIViewController, Parameters) -> Void)? = nil) {
            let instance = { () -> UIViewController in
                let bundle = bundle.flatMap { NSBundle(identifier: $0) }
                    ?? NSBundle(forClass: controller)
                let storyboard = UIStoryboard(name: storyboard, bundle: bundle)
                return storyboard.instantiateViewControllerWithIdentifier(identifier)
            }
            map(pattern,
                contained: contained,
                style: style,
                instance: instance,
                setup: setup)
    }
    
    public func map(pattern: String,
        nib: String,
        bundle: String? = nil,
        controller: UIViewController.Type = UIViewController.self,
        contained: Bool = false,
        style: PresentationStyle = .Show,
        setup: ((UIViewController, Parameters) -> Void)? = nil) {
            let instance = { () -> UIViewController in
                let bundle = bundle.flatMap { NSBundle(identifier: $0) }
                    ?? NSBundle(forClass: controller)
                return controller.init(nibName: nib, bundle: bundle)
            }
            map(pattern,
                contained: contained,
                style: style,
                instance: instance,
                setup: setup)
    }
    
    public func map(pattern: String,
        contained: Bool = false,
        style: PresentationStyle = .Show,
        instance: () -> UIViewController,
        setup: ((UIViewController, Parameters) -> Void)? = nil) {
            let mapHandler: MapHandler = { (route, parameters, completed) in
                guard let root = UIApplication.sharedApplication().keyWindow?.rootViewController else {
                    completed()
                    return
                }
                
                var vc = instance()
                if contained {
                    vc = UINavigationController(rootViewController: vc);
                }
                setup?(vc, parameters)
                
                var presenter = root
                while let nextVC = presenter.nextViewController() {
                    presenter = nextVC
                }
                
                switch style {
                case .Show:
                    CATransaction.begin()
                    CATransaction.setCompletionBlock(completed)
                    presenter.showViewController(vc, sender: nil)
                    CATransaction.commit()
                    break
                case .ShowDetail:
                    CATransaction.begin()
                    CATransaction.setCompletionBlock(completed)
                    presenter.showDetailViewController(vc, sender: nil)
                    CATransaction.commit()
                    break
                case let .Present(animated):
                    presenter.presentViewController(vc, animated: animated(), completion: completed)
                    break
                case let .Push(animated):
                    if let presenter = presenter as? UINavigationController {
                        CATransaction.begin()
                        CATransaction.setCompletionBlock(completed)
                        presenter.pushViewController(vc, animated: animated())
                        CATransaction.commit()
                    }
                    
                    if let presenter = presenter.navigationController {
                        CATransaction.begin()
                        CATransaction.setCompletionBlock(completed)
                        presenter.pushViewController(vc, animated: animated())
                        CATransaction.commit()
                    }
                    break
                case let .Custom(custom):
                    custom(presenting: presenter, presented: vc, completed: completed)
                    break
                }
            }
            
            self.map(pattern, handler: mapHandler)
    }
    
}

internal protocol nextViewControllerIterator {
    func nextViewController() -> UIViewController?
}

extension UITabBarController {
    internal override func nextViewController() -> UIViewController? {
        return selectedViewController
    }
}

extension UINavigationController {
    internal override func nextViewController() -> UIViewController? {
        return visibleViewController
    }
}

extension UIViewController : nextViewControllerIterator {
    internal func nextViewController() -> UIViewController? {
        return presentedViewController
    }
}
