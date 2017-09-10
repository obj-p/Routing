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
