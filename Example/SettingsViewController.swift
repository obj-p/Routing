import Routing
import UIKit

var shouldPresentViewControllers = false

class SettingsViewController: UITableViewController {
    @IBOutlet weak var presentViewControllers: UISwitch!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.presentViewControllers.setOn(shouldPresentViewControllers, animated: false)
    }

    @IBAction func presentViewControllersChanged(_ sender: UISwitch) {
        shouldPresentViewControllers = sender.isOn
    }
}

extension SettingsViewController: RoutingViewControllerSource {
    static let viewControllerIdentifier = "settings"
    
    static func viewController(at routingIdentifierPath: [String],
                               with parameters: Parameters,
                               passing any: Any?) -> UIViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "SettingsViewController")
    }
}
