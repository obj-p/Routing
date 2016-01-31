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
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancel")
    }
    
    func cancel() {
        self.dismissViewControllerAnimated(true) {}
    }
    
}
