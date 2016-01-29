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
    var router = Routing.sharedRouter
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        router.proxy("/route/one/:color") { [weak self] (route, var parameters, next) in
            if self?.enableProxy == true { parameters["color"] = "red" }
            next(route, parameters)
        }
    }
    
    @IBAction func openURL(sender: AnyObject) {
        router.open(NSURL(string: "routingexample://route/one/green")!)
        router.open(NSURL(string: "routingexample://route/two")!)
        router.open(NSURL(string: "routingexample://route/two")!)
        router.open(NSURL(string: "routingexample://route/two")!)
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

