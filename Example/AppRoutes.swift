//
//  AppRoutes.swift
//  Example
//
//  Created by Jason Prasad on 1/29/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import UIKit
import Routing

public let router = Routing()

public func registerRoutes() {
    let presentationSetup: PresentationSetup = { vc, _ in
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: vc, action: #selector(vc.cancel))
    }
    
    router.map("routingexample://push/login",
               source: .Storyboard(storyboard: "Main", identifier: "LoginViewController", bundle: nil),
               style: .Push(animated: true))
    
    router.map("routingexample://present/login",
               source: .Storyboard(storyboard: "Main", identifier: "LoginViewController", bundle: nil),
               style: .InNavigationController(.Present(animated: true)),
               setup: presentationSetup)
    
    router.map("routingexample://push/accountinfo",
               source: .Storyboard(storyboard: "Main", identifier: "AccountInfoViewController", bundle: nil),
               style: .Push(animated: true))
    
    router.map("routingexample://present/accountinfo",
               source: .Storyboard(storyboard: "Main", identifier: "AccountInfoViewController", bundle: nil),
               style: .InNavigationController(.Present(animated: true)),
               setup: presentationSetup)
    
    router.map("routingexample://push/settings",
               source: .Storyboard(storyboard: "Main", identifier: "SettingsViewController", bundle: nil),
               style: .Push(animated: true))
    
    router.map("routingexample://present/settings",
               source: .Storyboard(storyboard: "Main", identifier: "SettingsViewController", bundle: nil),
               style: .InNavigationController(.Present(animated: true)),
               setup: presentationSetup)
    
    router.proxy("routingexample://*", tags: ["Views"]) { route, _, next in
        if shouldPresentViewControllers {
            next(route.stringByReplacingOccurrencesOfString("push", withString: "present"), nil)
        } else {
            next(nil, nil)
        }
    }
    
    router.proxy("/*/accountinfo", tags: ["Views"]) { route, parameters, next in
        if authenticated {
            next(nil, nil)
        } else {
            // TODO: improve this!
            router.open("routingexample://present/login?callback=\(route)")
            next("", nil)
        }
    }
    
    router.proxy("/*", tags: ["Views"]) { route, parameters, next in
        print("opened: route (\(route)) with parameters (\(parameters))")
        next(nil, nil)
    }
}

extension UIViewController {
    func cancel() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
