//
//  HomeViewController.swift
//  Routing
//
//  Created by Jason Prasad on 8/7/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import UIKit

class HomeViewController: UITableViewController, UITabBarDelegate {
    private enum Row: Int {
        case Login
        case AccountInfo
        case Settings
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch Row(rawValue: indexPath.row)! {
        case .Login:
            router.open("routingexample://login")
        case .AccountInfo:
            router.open("routingexample://accountinfo")
        case .Settings:
            router.open("routingexample://settings")
        }
    }
}
