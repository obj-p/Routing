//
//  RoutingiOS.swift
//  Routing
//
//  Created by Jason Prasad on 2/15/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import UIKit
import QuartzCore

/**
 */

public enum PresentingInstance {
    
    case Storyboard(storyboard: String, identifier: String, bundle: NSBundle?)
    case Nib(controller: UIViewController.Type, name: String?, bundle: NSBundle?)
    case Provided(() -> UIViewController)
    
}

/**
 */

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

public final class Routing: BaseRouting {
    
    public override init(){
        super.init()
    }
    
    /**
     Associates a closure to a string pattern. A Routing instance will execute the closure in the
     event of a matching URL using #open. Routing will only execute the first matching mapped route.
     This will be the last routed added with #map.
     
     ```code
     let router = Routing()
     router.map("routing://route") { parameters, completed in
     completed() // Must call completed or the router will halt!
     }
     ```
     
     - Parameter pattern:  A String pattern
     - Parameter queue:  A dispatch queue for the callback
     - Parameter handler:  A MapHandler
     */
    
    public override func map(pattern: String,
        queue: dispatch_queue_t = dispatch_get_main_queue(),
        handler: MapHandler) {
            super.map(pattern, queue: queue, handler: handler)
    }
    
    /**
     Associates a closure to a string pattern. A Routing instance will execute the closure in the
     event of a matching URL using #open. Routing will execute all proxies unless #next() is called
     with non nil arguments.
     
     ```code
     let router = Routing()
     router.proxy("routing://route") { route, parameters, next in
     next(route, parameters) // Must call next or the router will halt!
     /* alternatively, next(nil, nil) allowing additional proxies to execute */
     }
     ```
     
     - Parameter pattern:  A String pattern
     - Parameter queue:  A dispatch queue for the callback
     - Parameter handler:  A ProxyHandler
     */
    
    public override func proxy(pattern: String,
        queue: dispatch_queue_t = dispatch_get_main_queue(),
        handler: ProxyHandler) {
            super.proxy(pattern, queue: queue, handler: handler)
    }
    
    /**
     Will execute the first mapped closure and any proxies with matching patterns. Mapped closures
     are read in a last to be mapped first executed order.
     
     - Parameter string:  A string represeting a URL
     - Returns:  A Bool. True if the string is a valid URL and it can open the URL, false otherwise
     */
    
    public override func open(string: String) -> Bool {
        return super.open(string)
    }
    
    /**
     Will execute the first mapped closure and any proxies with matching patterns. Mapped closures
     are read in a last to be mapped first executed order.
     
     - Parameter URL:  A URL
     - Returns:  A Bool. True if it can open the URL, false otherwise
     */
    
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
