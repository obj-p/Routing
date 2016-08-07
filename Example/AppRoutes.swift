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
    router.map("routingexample://login",
               source: .Storyboard(storyboard: "Main", identifier: "LoginViewController", bundle: nil),
               style: .Push(animated: true))
    
    router.map("routingexample://present/login",
               source: .Storyboard(storyboard: "Main", identifier: "LoginViewController", bundle: nil),
               style: .InNavigationController(.Present(animated: true)))
    
    router.map("routingexample://accountinfo",
               source: .Storyboard(storyboard: "Main", identifier: "AccountInfoViewController", bundle: nil),
               style: .Push(animated: true))
    
    router.map("routingexample://present/login",
               source: .Storyboard(storyboard: "Main", identifier: "AccountInfoViewController", bundle: nil),
               style: .InNavigationController(.Present(animated: true)))
    
    router.map("routingexample://settings",
               source: .Storyboard(storyboard: "Main", identifier: "SettingsViewController", bundle: nil),
               style: .Push(animated: true))
    
    router.map("routingexample://present/settings",
               source: .Storyboard(storyboard: "Main", identifier: "SettingsViewController", bundle: nil),
               style: .InNavigationController(.Present(animated: true)))
    
    router.proxy("/*", tags: ["Logs"]) { route, parameters, next in
        print("opened: route (\(route)) with parameters (\(parameters))")
        next(nil, nil)
    }
}
