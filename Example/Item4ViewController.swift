//
//  Item4ViewController.swift
//  iOS Example
//
//  Created by Jason Prasad on 3/8/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import UIKit

public class Item4ViewController: UIViewController {

    public var callback: String?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    internal func done() {
        self.dismissViewControllerAnimated(true) {
            if let callback = self.callback {
                AppRoutes.sharedRouter.open(callback)
            }
        }
    }

}
