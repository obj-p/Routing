//
//  AppRoutes.swift
//  Example
//
//  Created by Jason Prasad on 1/29/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import Foundation
import Routing

internal extension Routing {
    static var sharedRouter = { Routing() }()
    
    internal func registerRoutes() {
        
        Routing.sharedRouter.map("/two") { (parameters, completed) in
            guard let window = UIApplication.sharedApplication().delegate?.window else {
                completed()
                return
            }
            
            let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            let vc = storyboard.instantiateViewControllerWithIdentifier("one")
            let animated: Bool = parameters["animated"] == "true"
            
            CATransaction.begin()
            CATransaction.setCompletionBlock(completed)
            (window?.rootViewController?.presentedViewController as? UINavigationController)?.pushViewController(vc, animated: animated)
            CATransaction.commit()
        }
        
        Routing.sharedRouter.map("/one") { (parameters, completed) in
            guard let window = UIApplication.sharedApplication().delegate?.window else {
                completed()
                return
            }
            
            let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            let vc = storyboard.instantiateViewControllerWithIdentifier("one")
            
            let textField = UITextField()
            textField.text = "Tap to dismiss view"
            textField.frame.origin = CGPointMake(10,80)
            textField.sizeToFit()
            vc.view.addSubview(textField)
            
            let navController = UINavigationController(rootViewController: vc)
            let animated: Bool = parameters["animated"] == "true"
            window?.rootViewController?.presentViewController(navController, animated: animated, completion: completed)
        }
        
    }
}


