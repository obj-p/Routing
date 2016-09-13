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
    let presentationSetup: PresentationSetup = { vc, _, _ in
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel,
                                                              target: vc,
                                                              action: #selector(vc.cancel))
    }

    router.map("routingexample://push/login",
               source: .Storyboard(storyboard: "Main", identifier: "LoginViewController", bundle: nil),
               style: .Push(animated: true))

    router.map("routingexample://present/login",
               source: .Storyboard(storyboard: "Main", identifier: "LoginViewController", bundle: nil),
               style: .InNavigationController(.Present(animated: true)),
               setup: presentationSetup)

    router.map("routingexample://push/privilegedinfo",
               source: .Storyboard(storyboard: "Main", identifier: "PrivilegedInfoViewController", bundle: nil),
               style: .Push(animated: true))

    router.map("routingexample://present/privilegedinfo",
               source: .Storyboard(storyboard: "Main", identifier: "PrivilegedInfoViewController", bundle: nil),
               style: .InNavigationController(.Present(animated: true)),
               setup: presentationSetup)

    router.map("routingexample://push/settings",
               source: .Storyboard(storyboard: "Main", identifier: "SettingsViewController", bundle: nil),
               style: .Push(animated: true))

    router.map("routingexample://present/settings",
               source: .Storyboard(storyboard: "Main", identifier: "SettingsViewController", bundle: nil),
               style: .InNavigationController(.Present(animated: true)),
               setup: presentationSetup)

    router.proxy("routingexample://*", tags: ["Views"]) { route, _, _, next in
        if shouldPresentViewControllers {
            let route = route.stringByReplacingOccurrencesOfString("push", withString: "present")
            next(route, nil, nil)
        } else {
            next(nil, nil, nil)
        }
    }

    router.proxy("/*/privilegedinfo", tags: ["Views"]) { route, parameters, data, next in
        if authenticated {
            next(nil, nil, nil)
        } else {
            next("routingexample://present/login?callback=\(route)", parameters, data)
        }
    }

    router.proxy("/*", tags: ["Views"]) { route, parameters, data, next in
        print("opened: route (\(route)) with parameters (\(parameters)) & data (\(data))")
        next(nil, nil, nil)
    }
}

extension UIViewController {
    func cancel() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
