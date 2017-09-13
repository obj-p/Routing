import UIKit
import QuartzCore

public protocol RoutingViewControllerSource {
    static var viewControllerIdentifier: String { get }
    static func viewController(at routingIdentifierPath: [String],
                               with parameters: Parameters,
                               passing any: Any?) -> UIViewController?
}

public indirect enum RoutingPresentationStyle {
    case show
    case showDetail
    case present(animated: Bool)
    case push(animated: Bool)
    case custom(custom: (_ presenting: UIViewController,
        _ presented: UIViewController,
        _ completed: Completion) -> Void)
    case inNavigationController(RoutingPresentationStyle)
}

public extension UINavigationController {
    @discardableResult
    func popViewControllerAnimated(animated: Bool, completion: @escaping Completion) -> UIViewController? {
        var vc: UIViewController?
        self.commit(completion) {
            vc = self.popViewController(animated: animated)
        }
        return vc
    }
    
    @discardableResult
    func popToViewControllerAnimated(_ viewController: UIViewController,
                                     animated: Bool,
                                     completion: @escaping Completion) -> [UIViewController]? {
        var stack: [UIViewController]?
        self.commit(completion) {
            stack = self.popToViewController(viewController, animated: animated)
        }
        return stack
    }
    
    @discardableResult
    func popToRootViewControllerAnimated(animated: Bool, completion: @escaping Completion) -> [UIViewController]? {
        var stack: [UIViewController]?
        self.commit(completion) {
            stack = self.popToRootViewController(animated: animated)
        }
        return stack
    }
}

public extension UIViewController {
    func pushViewController(_ viewController: UIViewController,
                            animated: Bool,
                            completion: @escaping Completion) {
        let pusher = (self as? UINavigationController) ?? self.navigationController
        self.commit(completion) {
            pusher?.pushViewController(viewController, animated: animated)
        }
    }
    
    func showViewController(_ viewController: UIViewController,
                            sender: AnyObject?,
                            completion: @escaping Completion) {
        self.commit(completion) {
            self.show(viewController, sender: sender)
        }
    }
    
    func showDetailViewController(_ viewController: UIViewController,
                                  sender: AnyObject?,
                                  completion: @escaping Completion) {
        self.commit(completion) {
            self.showDetailViewController(viewController, sender: sender)
        }
    }
    
    func commit(_ completion: @escaping Completion, transition: () -> ()) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        transition()
        CATransaction.commit()
    }
}

private extension UIViewController {
    var topMostViewController: UIViewController {
        if let vc = (self as? UITabBarController)?.selectedViewController {
            return vc.topMostViewController
        } else if let vc = (self as? UINavigationController)?.visibleViewController {
            return vc.topMostViewController
        } else if let vc = presentedViewController {
            return vc.topMostViewController
        } else if let vc = childViewControllers.last {
            return vc.topMostViewController
        }
        return self
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
    func map(_ source: RoutingViewControllerSource.Type,
             tags: [String] = ["Views"],
             owner: RouteOwner? = nil) -> RouteUUID {
        let routeHandler: RouteHandler = { [weak self] (route, parameters, any, completed) in
            guard let root = UIApplication.shared.delegate?.window??.rootViewController,
                let vc = source.viewController(at: [""], with: parameters, passing: any) else {
                    completed()
                    return
            }
            
            let presenter = root.topMostViewController
            self?.showController(vc, from: presenter,
                                 with: .push(animated: true),
                                 completion: completed)
        }
        
        return map(source.viewControllerIdentifier,
                   tags: tags,
                   queue: DispatchQueue.main,
                   owner: owner,
                   handler: routeHandler)
    }
    
    private func showController(_ presented: UIViewController,
                                from presenting: UIViewController,
                                with style: RoutingPresentationStyle,
                                completion: @escaping Completion) {
        switch style {
        case .show:
            presenting.showViewController(presented,
                                          sender: self,
                                          completion: completion)
            break
        case .showDetail:
            presenting.showDetailViewController(presented,
                                                sender: self,
                                                completion: completion)
            break
        case let .present(animated):
            presenting.present(presented,
                               animated: animated,
                               completion: completion)
            break
        case let .push(animated):
            presenting.pushViewController(presented,
                                          animated: animated,
                                          completion: completion)
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
