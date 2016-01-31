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
    var router = Routing.sharedRouter

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        Routing.sharedRouter.registerRoutes()
        
        var components = NSURLComponents(URL: AppRoutes.urls.first, resolvingAgainstBaseURL: false)!
        components.query = "animated=false"
        Routing.sharedRouter.open(components.URL!)
        components = NSURLComponents(URL: AppRoutes.urls.second, resolvingAgainstBaseURL: false)!
        components.query = "animated=false"
        Routing.sharedRouter.open(components.URL!)
        
        return true
    }

    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        return router.open(url)
    }


}

