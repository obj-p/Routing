//
//  iOS.swift
//  Routing
//
//  Created by Jason Prasad on 5/31/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import UIKit
import QuartzCore

public enum ControllerSource {
    case Storyboard(storyboard: String, identifier: String, bundle: NSBundle?)
    case Nib(controller: UIViewController.Type, name: String?, bundle: NSBundle?)
    case Provided(() -> UIViewController)
}

public indirect enum PresentationStyle {
    case Show
    case ShowDetail
    case Present(animated: Bool)
    case Push(animated: Bool)
    case Custom(custom: (presenting: UIViewController,
        presented: UIViewController,
        completed: Completed) -> Void)
    case InNavigationController(PresentationStyle)
}

public typealias PresentationSetup = (UIViewController, Parameters, Data?) -> Void

public protocol RoutingPresentationSetup {
    func setup(route: String, parameters: Parameters, data: Data?)
}

public extension UINavigationController {
    public func pushViewController(vc: UIViewController, animated: Bool, completion: Completed) {
        self.commit(completion) {
            self.pushViewController(vc, animated: animated)
        }
    }

    public func popViewControllerAnimated(animated: Bool, completion: Completed) -> UIViewController? {
        var vc: UIViewController?
        self.commit(completion) {
            vc = self.popViewControllerAnimated(animated)
        }
        return vc
    }

    public func popToViewControllerAnimated(viewController: UIViewController, animated: Bool, completion: Completed) -> [UIViewController]? {
        var vc: [UIViewController]?
        self.commit(completion) {
            vc = self.popToViewController(viewController, animated: animated)
        }
        return vc
    }

    public func popToRootViewControllerAnimated(animated: Bool, completion: Completed) -> [UIViewController]? {
        var vc: [UIViewController]?
        self.commit(completion) {
            vc = self.popToRootViewControllerAnimated(animated)
        }
        return vc
    }
}

public extension UIViewController {
    public func showViewController(vc: UIViewController, sender: AnyObject?, completion: Completed) {
        self.commit(completion) {
            self.showViewController(vc, sender: sender)
        }
    }

    public func showDetailViewController(vc: UIViewController, sender: AnyObject?, completion: Completed) {
        self.commit(completion) {
            self.showDetailViewController(vc, sender: sender)
        }
    }

    private func commit(completed: Completed, transition: () -> Void) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completed)
        transition()
        CATransaction.commit()
    }
}

internal protocol ControllerIterator {
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

extension UIViewController : ControllerIterator {
    internal func nextViewController() -> UIViewController? {
        return presentedViewController
    }
}

public extension Routing {
    /**
     Associates a view controller presentation to a string pattern. A Routing instance present the
     view controller in the event of a matching URL using #open. Routing will only execute the first
     matching mapped route. This will be the last route added with #map.

     ```code
     let router = Routing()
     router.map("routingexample://route",
     instance: .Storyboard(storyboard: "Main", identifier: "ViewController", bundle: nil),
     style: .Present(animated: true)) { vc, parameters in
     ... // Useful callback for setup such as embedding in navigation controller
     return vc
     }
     ```

     - Parameter pattern:  A String pattern
     - Parameter tag:  A tag to reference when subscripting a Routing object
     - Parameter owner: The routes owner. If deallocated the route will be removed.
     - Parameter source: The source of the view controller instance
     - Parameter style:  The presentation style in presenting the view controller
     - Parameter setup:  A closure provided for additional setup
     - Returns:  The RouteUUID
     */

    public func map(pattern: String,
                    tags: [String] = ["Views"],
                    owner: RouteOwner? = nil,
                    source: ControllerSource,
                    style: PresentationStyle = .Show,
                    setup: PresentationSetup? = nil) -> RouteUUID {
        let routeHandler: RouteHandler = { [unowned self] (route, parameters, data, completed) in
            guard let root = UIApplication.sharedApplication().keyWindow?.rootViewController else {
                completed()
                return
            }

            let strongSelf = self
            let vc = strongSelf.controller(from: source)
            (vc as? RoutingPresentationSetup)?.setup(route, parameters: parameters, data: data)
            setup?(vc, parameters, data)

            var presenter = root
            while let nextVC = presenter.nextViewController() {
                presenter = nextVC
            }

            strongSelf.showController(vc, from: presenter, with: style, completion: completed)
        }

        return self.map(pattern, tags: tags, owner: owner, queue: dispatch_get_main_queue(), handler: routeHandler)
    }

    private func controller(from source: ControllerSource) -> UIViewController {
        switch source {
        case let .Storyboard(storyboard, identifier, bundle):
            let storyboard = UIStoryboard(name: storyboard, bundle: bundle)
            return storyboard.instantiateViewControllerWithIdentifier(identifier)
        case let .Nib(controller, name, bundle):
            return controller.init(nibName: name, bundle: bundle)
        case let .Provided(provider):
            return provider()
        }
    }

    private func showController(presented: UIViewController,
                                from presenting: UIViewController,
                                     with style: PresentationStyle,
                                          completion: Completed) {
        switch style {
        case .Show:
            presenting.showViewController(presented, sender: self, completion: completion)
            break
        case .ShowDetail:
            presenting.showDetailViewController(presented, sender: self, completion:  completion)
            break
        case let .Present(animated):
            presenting.presentViewController(presented, animated: animated, completion: completion)
            break
        case let .Push(animated):
            if let presenting = presenting as? UINavigationController {
                presenting.pushViewController(presented, animated: animated, completion: completion)
            } else {
                presenting.navigationController?.pushViewController(presented, animated: animated, completion: completion)
            }
        case let .Custom(custom):
            custom(presenting: presenting, presented: presented, completed: completion)
            break
        case let .InNavigationController(style):
            showController(UINavigationController(rootViewController: presented),
                           from: presenting,
                           with: style,
                           completion: completion)
            break
        }
    }
}
