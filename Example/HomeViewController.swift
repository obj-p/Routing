//
//  HomeViewController.swift
//  Routing
//
//  Created by Jason Prasad on 8/7/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import UIKit

class HomeViewController: UITableViewController {
    private enum Row: Int {
        case Login
        case Logout
        case AccountInfo
        case Settings
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
}

// MARK: Table View Delegate
extension HomeViewController {
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch Row(rawValue: indexPath.row)! {
        case .Login:
            router["Views"].open("routingexample://push/login")
        case .Logout:
            authenticated = false
            self.tableView.reloadData()
        case .AccountInfo:
            router["Views"].open("routingexample://push/accountinfo")
        case .Settings:
            router["Views"].open("routingexample://push/settings")
        }
    }
}

// MARK: Table View Datasource
extension HomeViewController {
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if case .Login = Row(rawValue: indexPath.row)! where authenticated == true {
            return 0.0
        } else if case .Logout = Row(rawValue: indexPath.row)! where authenticated == false {
            return 0.0
        }
        return 44.0
    }
}
