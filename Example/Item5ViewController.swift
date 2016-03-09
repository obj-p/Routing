//
//  Item5ViewController.swift
//  iOS Example
//
//  Created by Jason Prasad on 3/8/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import UIKit

public class Item5ViewController: UIViewController {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func pushLastViewController(sender: AnyObject) {
        AppRoutes.sharedRouter.open("routingexample://pushlastviewcontroller")
    }
    
}
