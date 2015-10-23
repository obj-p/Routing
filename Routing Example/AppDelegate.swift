//
//  AppDelegate.swift
//  Routing Example
//
//  Created by Jason Prasad on 10/1/15.
//  Copyright © 2015 Routing. All rights reserved.
//

import UIKit
import Routing

extension Routing {
    static var sharedRouter = { Routing() }()
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var router = Routing.sharedRouter
    var vc = UIViewController()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        router.map("/route/one/:color") { (parameters) in
            self.vc.view.bounds = self.window!.frame
            
            switch parameters["color"]! {
            case "red":
                self.vc.view.backgroundColor = UIColor.redColor()
            case "blue":
                self.vc.view.backgroundColor = UIColor.blueColor()
            default:
                self.vc.view.backgroundColor = UIColor.greenColor()
            }
            
            self.vc.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissVC"))
            self.window?.rootViewController?.showViewController(self.vc, sender: self)
        }
                
        return true
    }

    func dismissVC() -> Void {
        self.vc.dismissViewControllerAnimated(true, completion:nil)
    }
    
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        return router.open(url)
    }


}

