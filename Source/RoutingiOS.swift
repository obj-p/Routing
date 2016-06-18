//
//  RoutingiOS.swift
//  Routing
//
//  Created by Jason Prasad on 5/31/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import UIKit
import QuartzCore

public enum PresentedInstance {
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

/**
 */

public typealias PresentationSetup = (UIViewController, Parameters) -> UIViewController

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

public extension Routing {
    public func map(pattern: String,
                    instance: PresentedInstance,
                    style: PresentationStyle = .Show,
                    setup: PresentationSetup? = nil) {
        let routeHandler: RouteHandler = { [weak self] (route, parameters, completed) in
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
            case let .Push(animated) where presenter.isKindOfClass(UINavigationController):
                self?.wrapInCATransaction(completed) {
                    (presenter as? UINavigationController)?.pushViewController(vc, animated: animated)
                }
            case let .Push(animated) where presenter.navigationController != nil:
                self?.wrapInCATransaction(completed) {
                    presenter.navigationController?.pushViewController(vc, animated: animated)
                }
                break
            case let .Custom(custom):
                custom(presenting: presenter, presented: vc, completed: completed)
                break
            default:
                completed()
                break
            }
        }
        
        self.map(pattern, handler: routeHandler)
    }
    
    private func wrapInCATransaction(completed: Completed, transition: () -> Void) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completed)
        transition()
        CATransaction.commit()
    }
}
