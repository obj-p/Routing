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
            AppRoutes.sharedRouter.open(AppRoutes.urls.first)
            break
        case 1:
            AppRoutes.sharedRouter.open(AppRoutes.urls.second)
            break
        default:
            break
        }
    }
    
    @IBAction func enableProxy(sender: UIButton) {
        guard let text = sender.titleLabel?.text else {
            return
        }
        
        switch text {
        case "Enable Proxy":
            sender.setTitle("Disable Proxy", forState: .Normal)
            AppRoutes.isProxying = true
            break
        case "Disable Proxy":
            sender.setTitle("Enable Proxy", forState: .Normal)
            AppRoutes.isProxying = false
            break
        default:
            break
        }
    }
    
}

