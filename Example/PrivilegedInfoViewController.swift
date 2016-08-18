//
//  PrivilegedInfoViewController.swift
//  Routing
//
//  Created by Jason Prasad on 8/7/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import UIKit
import Routing

class PrivilegedInfoViewController: UIViewController, RouteOwner {
    override func viewDidLoad() {
        router.map("routingexample://secret",
                   owner: self,
                   source: .Storyboard(storyboard: "Main", identifier: "SecretViewController", bundle: nil),
                   style: .Push(animated: true))
    }
}
