//
//  LoginViewController.swift
//  Routing
//
//  Created by Jason Prasad on 8/7/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import UIKit
import Routing

var authenticated = false

class LoginViewController: UIViewController, RoutingPresentationSetup {
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    var callback: String?

    func setup(route: String, parameters: Parameters, data: Data?) {
        if let callbackURL = parameters["callback"] {
            self.callback = callbackURL
        }
    }

    @IBAction func login() {
        guard let username = username.text, let password = password.text where username != "" && password != ""  else {
            return
        }

        let completion = {
            if let callback = self.callback {
                router.open(callback, data: ["opened from login": NSDate()])
            }
        }

        authenticated = true
        if isModal {
            self.dismissViewControllerAnimated(true, completion: completion)
        } else {
            self.navigationController?.popViewControllerAnimated(true, completion: completion)
        }
    }
}

extension LoginViewController {
    var isModal: Bool {
        if let presented = self.presentingViewController?.presentedViewController, let navigationController = self.navigationController
            where presented == navigationController {
            return true
        }
        return false
    }
}
