//
//  ViewController.swift
//  Routing Example
//
//  Created by Jason Prasad on 10/1/15.
//  Copyright © 2015 Routing. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func openURL(sender: AnyObject) {
        UIApplication.sharedApplication().openURL(NSURL(string: "routingexample://route/one/1234")!)
    }

}

