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
    case storyboard(storyboard: String, identifier: String, bundle: Bundle?)
    case nib(controller: UIViewController.Type, name: String?, bundle: Bundle?)
    case provided(() -> UIViewController)
}

public indirect enum PresentationStyle {
    case show
    case showDetail
    case present(animated: Bool)
    case push(animated: Bool)
    case custom(custom: (_ presenting: UIViewController,
        _ presented: UIViewController,
        _ completed: Completed) -> Void)
    case inNavigationController(PresentationStyle)
}

public typealias PresentationSetup = (UIViewController, Parameters, Any?) -> Void

public protocol RoutingPresentationSetup {
    func setup(_ route: String, with parameters: Parameters, passing any: Any?)
}

public extension UINavigationController {
    func pushViewController(_ vc: UIViewController, animated: Bool, completion: @escaping Completed) {
        self.commit(completion) {
            self.pushViewController(vc, animated: animated)
        }
    }
    
    @discardableResult
    func popViewControllerAnimated(_ animated: Bool, completion: @escaping Completed) -> UIViewController? {
        var vc: UIViewController?
        self.commit(completion) {
            vc = self.popViewController(animated: animated)
        }
        
        return vc
    }
    
    @discardableResult
    func popToViewControllerAnimated(_ viewController: UIViewController, animated: Bool, completion: @escaping Completed) -> [UIViewController]? {
        var vc: [UIViewController]?
        self.commit(completion) {
            vc = self.popToViewController(viewController, animated: animated)
        }
        
        return vc
    }
    
    @discardableResult
    func popToRootViewControllerAnimated(_ animated: Bool, completion: @escaping Completed) -> [UIViewController]? {
        var vc: [UIViewController]?
        self.commit(completion) {
            vc = self.popToRootViewController(animated: animated)
        }
        
        return vc
    }
}

public extension UIViewController {
    func showViewController(_ vc: UIViewController, sender: AnyObject?, completion: @escaping Completed) {
        self.commit(completion) {
            self.show(vc, sender: sender)
        }
    }
    
    func showDetailViewController(_ vc: UIViewController, sender: AnyObject?, completion: @escaping Completed) {
        self.commit(completion) {
            self.showDetailViewController(vc, sender: sender)
        }
    }
    
    fileprivate func commit(_ completed: @escaping Completed, transition: () -> Void) {
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
    
    @discardableResult
    func map(_ pattern: String,
             tags: [String] = ["Views"],
             owner: RouteOwner? = nil,
             source: ControllerSource,
             style: PresentationStyle = .show,
             setup: PresentationSetup? = nil) -> RouteUUID {
        let routeHandler: RouteHandler = { [unowned self] (route, parameters, any, completed) in
            guard let root = UIApplication.shared.keyWindow?.rootViewController else {
                completed()
                return
            }
            
            let strongSelf = self
            let vc = strongSelf.controller(from: source)
            (vc as? RoutingPresentationSetup)?.setup(route, with: parameters, passing: any)
            setup?(vc, parameters, any)
            
            var presenter = root
            while let nextVC = presenter.nextViewController() {
                presenter = nextVC
            }
            
            strongSelf.showController(vc, from: presenter, with: style, completion: completed)
        }
        
        return map(pattern, tags: tags, queue: DispatchQueue.main, owner: owner, handler: routeHandler)
    }
    
    private func controller(from source: ControllerSource) -> UIViewController {
        switch source {
        case let .storyboard(storyboard, identifier, bundle):
            let storyboard = UIStoryboard(name: storyboard, bundle: bundle)
            return storyboard.instantiateViewController(withIdentifier: identifier)
        case let .nib(controller, name, bundle):
            return controller.init(nibName: name, bundle: bundle)
        case let .provided(provider):
            return provider()
        }
    }
    
    private func showController(_ presented: UIViewController,
                                from presenting: UIViewController,
                                with style: PresentationStyle,
                                completion: @escaping Completed) {
        switch style {
        case .show:
            presenting.showViewController(presented, sender: self, completion: completion)
            break
        case .showDetail:
            presenting.showDetailViewController(presented, sender: self, completion:  completion)
            break
        case let .present(animated):
            presenting.present(presented, animated: animated, completion: completion)
            break
        case let .push(animated):
            if let presenting = presenting as? UINavigationController {
                presenting.pushViewController(presented, animated: animated, completion: completion)
            } else {
                presenting.navigationController?.pushViewController(presented, animated: animated, completion: completion)
            }
        case let .custom(custom):
            custom(presenting, presented, completion)
            break
        case let .inNavigationController(style):
            showController(UINavigationController(rootViewController: presented),
                           from: presenting,
                           with: style,
                           completion: completion)
            break
        }
    }
}
