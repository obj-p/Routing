//
//  Item1ViewController.swift
//  iOS Example
//
//  Created by Jason Prasad on 3/8/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import UIKit

class Item1ViewController: UIViewController {

    @IBAction func pushItem3(sender: AnyObject) {
        AppRoutes.sharedRouter.open(NSURL(string: "routingexample://pushitem3/Item1")!)
    }

    @IBAction func showItem3(sender: AnyObject) {
        AppRoutes.sharedRouter.open(NSURL(string: "routingexample://showitem3/Item1")!)
    }
    
}
