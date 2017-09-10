import UIKit

class HomeViewController: UITableViewController {
    fileprivate enum Row: Int {
        case login
        case logout
        case privilegedInfo
        case settings
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
}

// MARK: Table View Delegate
extension HomeViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Row(rawValue: (indexPath as NSIndexPath).row)! {
        case .login:
            router["Views"].open("routingexample://push/login")
        case .logout:
            authenticated = false
            self.tableView.reloadData()
        case .privilegedInfo:
            router["Views"].open("routingexample://push/privilegedinfo", passing: ["opened from the home view": Date()])
        case .settings:
            router["Views"].open("routingexample://push/settings")
        }
    }
}

// MARK: Table View Datasource
extension HomeViewController {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch Row(rawValue: (indexPath as NSIndexPath).row)! {
        case .login where authenticated == true: fallthrough
        case .logout where authenticated == false:
            return 0.0
        default:
            return 44.0
        }
    }
}
