//
//  AppRoutes.swift
//  Example
//
//  Created by Jason Prasad on 1/29/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import Foundation
import Routing

public struct AppRoutes {
    public static var sharedRouter: Navigating!
    public static let paths = Paths()
    public static let urls = URLs()
    
    public static let host = "routingexample://"
    public static let root = "root"
    public static let first = "first"
    public static let second = "second"
    
    public struct Paths {
        public let root = "\(host)\(AppRoutes.root)"
        public let first = "\(host)\(AppRoutes.root)/\(AppRoutes.first)"
        public let second = "\(host)\(AppRoutes.root)/\(AppRoutes.second)"
    }
    
    public struct URLs {
        public let root = NSURL(string: AppRoutes.paths.root)!
        public let first = NSURL(string: AppRoutes.paths.first)!
        public let second = NSURL(string: AppRoutes.paths.second)!
    }
    
    public static var isProxying = false
    public static func registerRoutes() {
// MARK: Proxies
        AppRoutes.sharedRouter.proxy("/*") {  route, parameters, next in
            print("Routing route: \(route) with parameters: \(parameters)")
            next(nil, nil)
        }
        
        AppRoutes.sharedRouter.proxy(AppRoutes.paths.first) { (var route, parameters, next) in
            if AppRoutes.isProxying { route = AppRoutes.paths.second }
            next(route, parameters)
        }
        
        AppRoutes.sharedRouter.proxy(AppRoutes.paths.second) { (var route, parameters, next) in
            if AppRoutes.isProxying { route = AppRoutes.paths.first }
            next(route, parameters)
        }

// MARK: Navigation Routes
        AppRoutes.sharedRouter.map(AppRoutes.paths.root,
            controller: RootViewController.self,
            contained: true,
            style: .Root,
            storyboard: "Main",
            identifier: AppRoutes.root) { vc, parameters in
                // Do something with parameters
        }
        
        let animated = { true }
        AppRoutes.sharedRouter.map(AppRoutes.paths.first,
            controller: FirstViewController.self,
            contained: true,
            style: .Present(animated: animated),
            storyboard: "Main",
            identifier: AppRoutes.first) { vc, parameters in
                // Do something with parameters
        }

        AppRoutes.sharedRouter.map(AppRoutes.paths.second,
            controller: SecondViewController.self,
            contained: true,
            style: .Push(animated: animated),
            storyboard: "Main",
            identifier: AppRoutes.second) { vc, parameters in
                // Do something with parameters
        }
    }
    
}
