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
                   source: .storyboard(storyboard: "Main", identifier: "SecretViewController", bundle: nil),
                   style: .push(animated: true))

        routeUUID = router.map("routingexample://present/secret",
                               source: .storyboard(storyboard: "Main", identifier: "SecretViewController", bundle: nil),
                               style: .inNavigationController(.present(animated: true))) { vc, _, _ in
                                vc.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                                                      target: vc,
                                                                                      action: #selector(vc.cancel))
        }
    }

    deinit {
        router.dispose(of: routeUUID)
    }
}

extension PrivilegedInfoViewController: RoutingPresentationSetup {

    func setup(_ route: String, with parameters: Parameters, passing any: Any?) {
        if let any = any as? [String: Date] {
            print("Passed date: \(any)")
        }
    }

}
