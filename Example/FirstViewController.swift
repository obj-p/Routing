//
//  FirstViewController.swift
//  Example
//
//  Created by Jason Prasad on 1/30/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import UIKit
import Routing

class FirstViewController: UIViewController {

    override func viewDidLoad() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Dismiss", style: .Plain, target: self, action: "dismiss")
    }
    
    func dismiss() {
        self.dismissViewControllerAnimated(true) {}
    }
    
}
