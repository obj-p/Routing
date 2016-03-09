//
//  Item3ViewController.swift
//  iOS Example
//
//  Created by Jason Prasad on 3/8/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import UIKit

public class Item3ViewController: UIViewController {

    public var labelText: String?
    
    @IBOutlet weak var label: UILabel!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if let labelText = labelText {
            self.label.text = labelText
        }
    }
    
    @IBAction func pushParentViewController(sender: AnyObject) {
        AppRoutes.sharedRouter.open("routingexample://pushparentviewcontroller")
    }

    internal func done() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
