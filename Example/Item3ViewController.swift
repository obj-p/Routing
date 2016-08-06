//
//  Item3ViewController.swift
//  iOS Example
//
//  Created by Jason Prasad on 3/8/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import UIKit
import Routing

public class Item3ViewController: UIViewController, RoutingPresentationSetup {

    public var labelText: String?
    
    @IBOutlet weak var label: UILabel!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if let labelText = labelText {
            self.label.text = labelText
        }
    }
    
    public func setup(route: String, parameters: Parameters) {
        guard let presenter = parameters["presenter"] else {
            return
        }
        
        if route.containsString("pushitem3") {
            self.labelText = "Pushed by: \(presenter)"
        } else if route.containsString("showitem3") {
            self.labelText = "Shown by: \(presenter)"
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(self.done))
        }
    }
    
    @IBAction func pushParentViewController(sender: AnyObject) {
        AppRoutes.sharedRouter.open("routingexample://pushparentviewcontroller")
    }

    internal func done() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
