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
    public static var sharedRouter: Routing = { Routing() }()
    
    public static func registerRoutes() {
        
        // MARK: Navigation Routes
        AppRoutes.sharedRouter.map("routingexample://presentitem3/:presenter",
            instance: .Storyboard(storyboard: "Main", identifier: "Item3", bundle: nil),
            style: .Present(animated: true)) { vc, parameters in
                if let presenter = parameters["presenter"], let vc = vc as? Item3ViewController {
                    vc.labelText = "Presented by: \(presenter)"
                }
                let nc = UINavigationController(rootViewController: vc)
                vc.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: vc, action: "done")
                return nc
        }
        
        AppRoutes.sharedRouter.map("routingexample://pushitem3/:presenter",
            instance: .Storyboard(storyboard: "Main", identifier: "Item3", bundle: nil),
            style: .Push(animated: true)) { vc, parameters in
                if let presenter = parameters["presenter"], let vc = vc as? Item3ViewController {
                    vc.labelText = "Pushed by: \(presenter)"
                }
                return vc
        }
        
        AppRoutes.sharedRouter.map("routingexample://showitem3/:presenter",
            instance: .Storyboard(storyboard: "Main", identifier: "Item3", bundle: nil),
            style: .ShowDetail) { vc, parameters in
                if let presenter = parameters["presenter"], let vc = vc as? Item3ViewController {
                    vc.labelText = "Shown by: \(presenter)"
                }
                let nc = UINavigationController(rootViewController: vc)
                vc.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: vc, action: "done")
                return nc
        }
        
        AppRoutes.sharedRouter.map("routingexample://presentitem4",
            instance: .Nib(controller: Item4ViewController.self, name: "Item4ViewController", bundle: nil),
            style: .Present(animated: true)) { vc, parameters in
                if let callback = parameters["callback"], let vc = vc as? Item4ViewController {
                    vc.callbackURL = NSURL(string: callback)!
                }
                let nc = UINavigationController(rootViewController: vc)
                vc.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: vc, action: "done")
                return nc
        }
        
        // MARK: Proxies        
        AppRoutes.sharedRouter.proxy("routingexample://presentitem3/:presenter") { (var route, parameters, next) in
            guard let presenter = parameters["presenter"] where presenter == "Item2" else {
                next(nil, nil)
                return
            }
            let range = route.rangeOfString("Item2")
            route.replaceRange(range!, with: "Item4")
            AppRoutes.sharedRouter.open(NSURL(string: "routingexample://presentitem4?callback=\(route)")!)
            next("", nil)
        }
        
        AppRoutes.sharedRouter.proxy("routingexample://showitem3/:presenter") { (var route, parameters, next) in
            guard let presenter = parameters["presenter"] where presenter == "Item2" else {
                next(nil, nil)
                return
            }
            let range = route.rangeOfString("Item2")
            route.replaceRange(range!, with: "Item4")
            AppRoutes.sharedRouter.open(NSURL(string: "routingexample://presentitem4?callback=\(route)")!)
            next("", nil)
        }

        
        AppRoutes.sharedRouter.proxy("/*") { route, parameters, next in
            print("Routing route: \(route) with parameters: \(parameters)")
            next(nil, nil)
        }
        
    }
    
}
