import UIKit
import Routing

class PrivilegedInfoViewController: UIViewController, RouteOwner {
    var routeUUID: RouteUUID = ""

    override func viewDidLoad() {
//        router.map("routingexample://push/secret",
//                   owner: self,
//                   source: .storyboard(storyboard: "Main", identifier: "SecretViewController", bundle: nil),
//                   style: .push(animated: true))
//
//        routeUUID = router.map("routingexample://present/secret",
//                               source: .storyboard(storyboard: "Main", identifier: "SecretViewController", bundle: nil),
//                               style: .inNavigationController(.present(animated: true))) { vc, _, _ in
//                                vc.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
//                                                                                      target: vc,
//                                                                                      action: #selector(vc.cancel))
//        }
    }

    deinit {
        router.dispose(of: routeUUID)
    }
}

extension PrivilegedInfoViewController: RoutingViewControllerSource {
    static let viewControllerIdentifier = "privilegedinfo"
    
    static func viewController(at routingIdentifierPath: [String],
                               with parameters: Parameters,
                               passing any: Any?) -> UIViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "PrivilegedInfoViewController")
        
        if let any = any as? [String: Date] {
            print("Passed date: \(any)")
        }
        
        return vc
    }
}
