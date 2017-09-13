import UIKit
import Routing

var authenticated = false

class LoginViewController: UIViewController {
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    var callback: String?
    
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
            _ = self.navigationController?.popViewControllerAnimated(animated: true, completion: completion)
        }
    }
}

extension LoginViewController: RoutingViewControllerSource {
    static let viewControllerIdentifier = "login"
    
    static func viewController(at routingIdentifierPath: [String],
                               with parameters: Parameters,
                               passing any: Any?) -> UIViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController
        
        if let callbackURL = parameters["callback"] {
            vc?.callback = callbackURL
        }
        
        return vc
    }
}

extension LoginViewController {
    var isModal: Bool {
        if let presented = self.presentingViewController?.presentedViewController,
            let navigationController = self.navigationController
            , presented == navigationController {
            return true
        }
        return false
    }
}
