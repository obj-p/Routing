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

    func setup(_ route: String, with parameters: Parameters, passing any: Any?) {
        if let callbackURL = parameters["callback"] {
            self.callback = callbackURL
        }
    }

    @IBAction func login() {
        guard let username = username.text, let password = password.text , username != "" && password != ""  else {
            return
        }

        let completion = {
            if let callback = self.callback {
                router.open(callback, passing: ["opened from login": Date()])
            }
        }

        authenticated = true
        if isModal {
            self.dismiss(animated: true, completion: completion)
        } else {
            _ = self.navigationController?.popViewControllerAnimated(true, completion: completion)
        }
    }
}

extension LoginViewController {
    var isModal: Bool {
        if let presented = self.presentingViewController?.presentedViewController, let navigationController = self.navigationController
            , presented == navigationController {
            return true
        }
        return false
    }
}
