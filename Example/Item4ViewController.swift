//
//  Item4ViewController.swift
//  iOS Example
//
//  Created by Jason Prasad on 3/8/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import UIKit

public class Item4ViewController: UIViewController {

    public var callbackURL: NSURL?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    internal func done() {
        self.dismissViewControllerAnimated(true) {
            if let callbackURL = self.callbackURL {
                AppRoutes.sharedRouter.open(callbackURL)
            }
        }
    }

}
