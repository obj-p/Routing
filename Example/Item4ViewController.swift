//
//  Item4ViewController.swift
//  iOS Example
//
//  Created by Jason Prasad on 3/8/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import UIKit
import Routing

public class Item4ViewController: UIViewController, RoutingPresentationSetup {

    public var callback: String?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    public func setup(route: String, parameters: Parameters) {
        if let callback = parameters["callback"] {
            self.callback = callback
        }
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(self.done))
    }
    
    internal func done() {
        self.dismissViewControllerAnimated(true) {
            if let callback = self.callback {
                AppRoutes.sharedRouter.open(callback)
            }
        }
    }

}
