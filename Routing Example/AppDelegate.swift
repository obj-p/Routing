//
//  AppDelegate.swift
//  Routing Example
//
//  Created by Jason Prasad on 10/1/15.
//  Copyright © 2015 Routing. All rights reserved.
//

import UIKit
import Routing

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var router = Routing()
    var vc = UIViewController()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        router.add("/route/one/:id") { (parameters) in
            self.vc.view.bounds = self.window!.frame
            self.vc.view.backgroundColor = UIColor.redColor()
            self.vc.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissVC"))
            self.window?.rootViewController?.showViewController(self.vc, sender: self)
        }
        
        return true
    }

    func dismissVC() -> Void {
        self.vc.dismissViewControllerAnimated(true, completion:nil)
        UIApplication.sharedApplication().openURL(NSURL(string: "routingexample://route/two/1234")!)
    }
    
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        return router.open(url)
    }


}

