//
//  AppRoutes.swift
//  Example
//
//  Created by Jason Prasad on 1/29/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import Foundation
import Routing

struct AppRoutes {
    internal static let urls = URLs()
    internal static let identifiers = Identifiers()
    
    internal static let host = "routingexample:/"
    internal static let root = "/root"
    internal static let first = "/root/first"
    internal static let second = "/root/first/second"
    
    internal struct URLs {
        internal let root = NSURL(string: AppRoutes.host + AppRoutes.root)!
        internal let first = NSURL(string: AppRoutes.host + AppRoutes.first)!
        internal let second = NSURL(string: AppRoutes.host + AppRoutes.second)!
    }
    
    internal struct Identifiers {
        internal let root = urls.root.lastPathComponent!
        internal let first = urls.first.lastPathComponent!
        internal let second = urls.second.lastPathComponent!
    }
}

internal extension Routing {
    
    static var sharedRouter = { Routing() }()
    static var isProxying = false
    
    internal func registerRoutes() {
        
        Routing.sharedRouter.proxy(AppRoutes.first) { (var route, parameters, next) in
            if Routing.isProxying { route = AppRoutes.second }
            next(route, parameters)
        }
        
        Routing.sharedRouter.map(AppRoutes.first) { (parameters, completed) in
            guard let window = UIApplication.sharedApplication().delegate?.window else {
                completed()
                return
            }
            
            let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            let vc = storyboard.instantiateViewControllerWithIdentifier(AppRoutes.identifiers.first)
            let navController = UINavigationController(rootViewController: vc)
            let animated: Bool = parameters["animated"] == nil || parameters["animated"] == "true"
            
            window?.rootViewController?.presentViewController(navController, animated: animated, completion: completed)
        }
        
        Routing.sharedRouter.proxy(AppRoutes.second) { (var route, parameters, next) in
            if Routing.isProxying { route = AppRoutes.first }
            next(route, parameters)
        }
        
        Routing.sharedRouter.map(AppRoutes.second) { (parameters, completed) in
            guard let window = UIApplication.sharedApplication().delegate?.window else {
                completed()
                return
            }
            
            let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            let vc = storyboard.instantiateViewControllerWithIdentifier(AppRoutes.identifiers.second)
            let animated: Bool = parameters["animated"] == nil || parameters["animated"] == "true"
            
            CATransaction.begin()
            CATransaction.setCompletionBlock(completed)
            if let presented = (window?.rootViewController?.presentedViewController as? UINavigationController) {
                presented.pushViewController(vc, animated: animated)
            } else {
                (window?.rootViewController as? UINavigationController)?.pushViewController(vc, animated: animated)
            }
            CATransaction.commit()
        }
        
    }
    
}


