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
    var routeUUID: RouteUUID = ""

    override func viewDidLoad() {
        router.map("routingexample://push/secret",
                   owner: self,
                   source: .Storyboard(storyboard: "Main", identifier: "SecretViewController", bundle: nil),
                   style: .Push(animated: true))

        routeUUID = router.map("routingexample://present/secret",
                               source: .Storyboard(storyboard: "Main", identifier: "SecretViewController", bundle: nil),
                               style: .InNavigationController(.Present(animated: true))) { vc, _, _ in
                                vc.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel,
                                                                                      target: vc,
                                                                                      action: #selector(vc.cancel))
        }
    }

    deinit {
        router.disposeOf(routeUUID)
    }
}

extension PrivilegedInfoViewController: RoutingPresentationSetup {

    func setup(route: String, parameters: Parameters, data: Data?) {
        if let data = data as? [String: NSDate] {
            print("Passed date: \(data)")
        }
    }

}
