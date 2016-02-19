//
//  AppDelegate.swift
//  Example
//
//  Created by Jason Prasad on 10/1/15.
//  Copyright © 2015 Routing. All rights reserved.
//

import UIKit
import Routing

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        AppRoutes.registerRoutes()
        AppRoutes.sharedRouter.open(AppRoutes.urls.first)
        AppRoutes.sharedRouter.open(AppRoutes.urls.second)
        
        return true
    }

    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        return AppRoutes.sharedRouter.open(url)
    }


}

