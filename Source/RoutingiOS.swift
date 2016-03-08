//
//  RoutingiOS.swift
//  Routing
//
//  Created by Jason Prasad on 2/15/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import UIKit

public enum PresentingInstance {
    
    case Storyboard(storyboard: String, identifier: String, bundle: NSBundle?)
    case Nib(controller: UIViewController.Type, name: String?, bundle: NSBundle?)
    case Provided(() -> UIViewController)
    
}

public enum PresentationStyle {
    
    case Show
    case ShowDetail
    case Present(animated: Bool)
    case Push(animated: Bool)
    case Custom(custom: (presenting: UIViewController,
        presented: UIViewController,
        completed: Completed) -> Void)
    
}

public typealias PresentationSetup = (UIViewController, Parameters) -> UIViewController

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
        instance: PresentingInstance,
        style: PresentationStyle = .Show,
        setup: PresentationSetup? = nil) {
            let mapHandler: MapHandler = { [weak self] (route, parameters, completed) in
                guard let root = UIApplication.sharedApplication().keyWindow?.rootViewController else {
                    completed()
                    return
                }
                
                var vc: UIViewController
                switch instance {
                case let .Storyboard(storyboard, identifier, bundle):
                    let storyboard = UIStoryboard(name: storyboard, bundle: bundle)
                    vc = storyboard.instantiateViewControllerWithIdentifier(identifier)
                    break
                case let .Nib(controller , name, bundle):
                    vc = controller.init(nibName: name, bundle: bundle)
                    break
                case let .Provided(provider):
                    vc = provider()
                    break
                }
                
                if let setup = setup {
                    vc = setup(vc, parameters)
                }
                
                var presenter = root
                while let nextVC = presenter.nextViewController() {
                    presenter = nextVC
                }
                
                switch style {
                case .Show:
                    self?.wrapInCATransaction(completed) {
                        presenter.showViewController(vc, sender: self)
                    }
                    break
                case .ShowDetail:
                    self?.wrapInCATransaction(completed) {
                        presenter.showDetailViewController(vc, sender: self)
                    }
                    break
                case let .Present(animated):
                    presenter.presentViewController(vc, animated: animated, completion: completed)
                    break
                case let .Push(animated):
                    if let presenter = presenter as? UINavigationController {
                        self?.wrapInCATransaction(completed) {
                            presenter.pushViewController(vc, animated: animated)
                        }
                    }
                    
                    if let presenter = presenter.navigationController {
                        self?.wrapInCATransaction(completed) {
                            presenter.pushViewController(vc, animated: animated)
                        }
                    }
                    break
                case let .Custom(custom):
                    custom(presenting: presenter, presented: vc, completed: completed)
                    break
                }
            }
            
            self.map(pattern, handler: mapHandler)
    }
 
    private func wrapInCATransaction(completed: Completed, transition: () -> Void) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completed)
        transition()
        CATransaction.commit()
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
