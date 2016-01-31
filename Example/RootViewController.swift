//
//  RootViewController.swift
//  Example
//
//  Created by Jason Prasad on 10/1/15.
//  Copyright © 2015 Routing. All rights reserved.
//

import UIKit
import Routing

class RootViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func openURL(sender: AnyObject) {
        switch sender.tag {
        case 0:
            Routing.sharedRouter.open(AppRoutes.urls.first)
            break
        case 1:
            Routing.sharedRouter.open(AppRoutes.urls.second)
            break
        default:
            break
        }
    }
    
}

