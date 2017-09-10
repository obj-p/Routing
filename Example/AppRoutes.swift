import UIKit
import Routing

public let router = Routing()

public func registerRoutes() {
    let presentationSetup: PresentationSetup = { vc, _, _ in
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                              target: vc,
                                                              action: #selector(vc.cancel))
    }

    router.map("routingexample://push/login",
               source: .storyboard(storyboard: "Main", identifier: "LoginViewController", bundle: nil),
               style: .push(animated: true))

    router.map("routingexample://present/login",
               source: .storyboard(storyboard: "Main", identifier: "LoginViewController", bundle: nil),
               style: .inNavigationController(.present(animated: true)),
               setup: presentationSetup)

    router.map("routingexample://push/privilegedinfo",
               source: .storyboard(storyboard: "Main", identifier: "PrivilegedInfoViewController", bundle: nil),
               style: .push(animated: true))

    router.map("routingexample://present/privilegedinfo",
               source: .storyboard(storyboard: "Main", identifier: "PrivilegedInfoViewController", bundle: nil),
               style: .inNavigationController(.present(animated: true)),
               setup: presentationSetup)

    router.map("routingexample://push/settings",
               source: .storyboard(storyboard: "Main", identifier: "SettingsViewController", bundle: nil),
               style: .push(animated: true))

    router.map("routingexample://present/settings",
               source: .storyboard(storyboard: "Main", identifier: "SettingsViewController", bundle: nil),
               style: .inNavigationController(.present(animated: true)),
               setup: presentationSetup)

    router.proxy("routingexample://*", tags: ["Views"]) { route, _, _, next in
        if shouldPresentViewControllers {
            let route = route.replacingOccurrences(of: "push", with: "present")
            next((route, Parameters(), nil))
        } else {
            next(nil)
        }
    }

    router.proxy("/*/privilegedinfo", tags: ["Views"]) { route, parameters, any, next in
        if authenticated {
            next(nil)
        } else {
            next(("routingexample://present/login?callback=\(route)", parameters, any))
        }
    }

    router.proxy("/*", tags: ["Views"]) { route, parameters, any, next in
        print("opened: route (\(route)) with parameters (\(parameters)) & passing (\(String(describing: any)))")
        next(nil)
    }
}

extension UIViewController {
    func cancel() {
        self.dismiss(animated: true, completion: nil)
    }
}
