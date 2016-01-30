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
    var vc = UIViewController()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        router.registerRoutes()
        router.open(NSURL(string: "routingexample://one?animated=false")!)
        router.open(NSURL(string: "routingexample://two?animated=false")!)
        router.open(NSURL(string: "routingexample://two?animated=false")!)
        router.open(NSURL(string: "routingexample://two?animated=false")!)
        router.open(NSURL(string: "routingexample://two?animated=false")!)
        return true
    }

    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        return router.open(url)
    }


}

