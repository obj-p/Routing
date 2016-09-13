//
//  SettingsViewController.swift
//  Routing
//
//  Created by Jason Prasad on 8/7/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import UIKit

var shouldPresentViewControllers = false

class SettingsViewController: UITableViewController {
    @IBOutlet weak var presentViewControllers: UISwitch!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.presentViewControllers.setOn(shouldPresentViewControllers, animated: false)
    }

    @IBAction func presentViewControllersChanged(sender: UISwitch) {
        shouldPresentViewControllers = sender.on
    }
}
