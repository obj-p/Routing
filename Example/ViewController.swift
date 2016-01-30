//
//  ViewController.swift
//  Example
//
//  Created by Jason Prasad on 10/1/15.
//  Copyright © 2015 Routing. All rights reserved.
//

import UIKit
import Routing

class ViewController: UIViewController {
    
    @IBOutlet weak var button: UIButton!
    
    var enableProxy = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func openURL(sender: AnyObject) {
        Routing.sharedRouter.open(NSURL(string: "routingexample://one?animated=true")!)
    }

    @IBAction func Proxy(sender: AnyObject) {
        self.enableProxy = self.enableProxy == false
        if self.enableProxy {
            self.button.setTitle("Disable Proxy", forState: UIControlState.Normal)
        } else {
            self.button.setTitle("Enable Proxy", forState: UIControlState.Normal)
        }
    }
    
}

