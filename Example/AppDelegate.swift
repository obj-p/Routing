//
//  AppDelegate.swift
//  Example
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
        router.map("/route/one/:color") { (parameters, completed) in
            self.vc.view.bounds = self.window!.frame
            
            let textField = UITextField()
            textField.text = "Tap to dismiss view"
            textField.frame.origin = CGPointMake(10,20)
            textField.sizeToFit()
            self.vc.view.addSubview(textField)
            
            switch parameters["color"]! {
            case "red":
                self.vc.view.backgroundColor = UIColor.redColor()
            default:
                self.vc.view.backgroundColor = UIColor.greenColor()
            }
            
            self.vc.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissVC"))
            self.window?.rootViewController?.showViewController(self.vc, sender: self)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(10 * Double(NSEC_PER_SEC))), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                completed()
            })
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

