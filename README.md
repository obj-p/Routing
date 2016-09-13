# Routing

[![Build Status](https://travis-ci.org/jwalapr/Routing.svg?branch=master)](https://travis-ci.org/jwalapr/Routing)
[![Code coverage status](https://img.shields.io/codecov/c/github/jwalapr/Routing.svg?style=flat-square)](http://codecov.io/github/jwalapr/Routing)
[![Platform support](https://img.shields.io/badge/platform-ios%20%7C%20osx%20%7C%20tvos%20%7C%20watchos-lightgrey.svg?style=flat-square)](https://img.shields.io/badge/platform-ios%20%7C%20osx%20%7C%20tvos%20%7C%20watchos-lightgrey.svg?style=flat-square) 
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Routing.svg)](https://cocoapods.org/pods/Routing)
[![License MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://github.com/Routing/Routing/blob/master/LICENSE)

## Usage

Let's say you have a table view controller that displays privileged information once a user selects a cell. An implementation of tableView:didSelectRowAtIndexPath: may look as such.

```swift
override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    switch Row(rawValue: indexPath.row)! {
    // ...
    case .PrivilegedInfo:
        router["Views"].open("routingexample://push/privilegedinfo")
    }
    // ...
}
```

Perhaps the privileged information is only available after a user authenticates with the service. After logging in we want the privileged information presented to the user right away. Without changing the above implementation we may proxy the intent and display a log in view, after which, a call back may present the privileged information screen.

```swift
router.proxy("/*/privilegedinfo", tags: ["Views"]) { route, parameters, data, next in
    if authenticated {
        next(nil, nil, nil)
    } else {
        next("routingexample://present/login?callback=\(route)", parameters, data)
    }
}
```

![Routing Proxy](http://i.giphy.com/l0MYulEzZgjlDkI1y.gif)

Eventually we may need to support a deep link to the privileged information from outside of the application. This can be handled in the AppDelegate simply as follows.

```swift
func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
    return router["Views"].open(url)
}
```

![Routing Deep Link](http://i.giphy.com/3o6ZtoFBVCKafruVMs.gif)

An example of other routes in an application may look like this.

```swift
let presentationSetup: PresentationSetup = { vc, _, _ in
    vc.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, 
                                                          target: vc, 
                                                          action: #selector(vc.cancel))
}

router.map("routingexample://present/login",
           source: .Storyboard(storyboard: "Main", identifier: "LoginViewController", bundle: nil),
           style: .InNavigationController(.Present(animated: true)),
           setup: presentationSetup)
    
router.map("routingexample://push/privilegedinfo",
           source: .Storyboard(storyboard: "Main", identifier: "PrivilegedInfoViewController", bundle: nil),
           style: .Push(animated: true))
    
router.map("routingexample://present/settings",
           source: .Storyboard(storyboard: "Main", identifier: "SettingsViewController", bundle: nil),
           style: .InNavigationController(.Present(animated: true)),
           setup: presentationSetup)
    
router.proxy("/*", tags: ["Views"]) { route, parameters, data, next in
    print("opened: route (\(route)) with parameters (\(parameters)) & data (\(data))")
    next(nil, nil, nil)
}
```

At its simplest, Routing allows the association of string patterns to closures. This allows for the expression of intent in certain areas of code and the implementation of it in another. UI may only be concerned with expressing the intent of transitioning to another view and the business logic may be handled elsewhere. Routing allows for the explicit documentation of an application's behavior and views through mappings and proxies.

## Installation

### CocoaPods

Via [CocoaPods](https://cocoapods.org/pods/Routing):

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod 'Routing', '~> 1.1.0'
```

### Carthage

Via [Carthage](https://github.com/Carthage/Carthage):

```ogdl
github "jwalapr/Routing"
```
## Further Detail

### Map

A router instance may map a string pattern to view controller navigation, as covered in the [Usage](#usage) section above, or just a closure as presented below. The closure will have four parameters. The route it matched, the parameters (both query and segments in the URL), any data passed through open, and a completion closure that must be called or the router will halt all subsequent calls to #open.

```swift
router.map("routingexample://route/:argument") { route, parameters, data, completed in
    argument = parameters["argument"]
    completed()
}
```

### Proxy

A router instance may proxy any string pattern. The closure will also have four parameters. The route it matched, the parameters, any data passed, and a next closure. The next closure accepts three optional arguments for the route, parameters, and data. If nil is passed to all arguments then the router will continue to another proxy if it exists or subsequently to a mapped route. If a proxy were to pass a route, parameters, or data to the next closure, the router will skip any subsequent proxy and attempt to match a mapped route. Failure to call next will halt the router and all subsequent calls to #open. 

```swift
router.proxy("routingexample://route/one") { route, parameters, data, next -> Void in
    next("routingexample://route/two", parameters, data)
}
```

### Order of Map or Proxy

In general, the last call to register a map or proxy to the router will be first called in the event of a matched URL respectively. Proxies will be serviced first and then a map.

### Tags

A tag may be passed to maps or proxies. The default tag for maps to view controller navigation is "Views". Tags allow for the router to be subscripted to a specific context. If a router is subscripted with "Views", then it will only attempt to find routes that are tagged as such.

```swift
router.proxy("/*", tags: ["Views, Logs"]) { route, parameters, data, next in
    print("opened: route (\(route)) with parameters (\(parameters)) & data (\(data))")
    next(nil, nil, nil)
}

router["Views", "Logs", "Actions"].open(url)

router["Views"].open(url, data: NSDate()) // pass any data if needed

router.open(url) // - or - to search all routes...

```

### Route Owner

Routes may have a RouteOwner specified when using #map or #proxy. When the RouteOwner is deallocated, the route is removed from the Routing instance.

```swift
public protocol RouteOwner: class {}

class PrivilegedInfoViewController: UIViewController, RouteOwner {
    override func viewDidLoad() {
        router.map("routingexample://secret",
                   owner: self,
                   source: .Storyboard(storyboard: "Main", identifier: "SecretViewController", bundle: nil),
                   style: .Push(animated: true))
    }
}
```

### RouteUUID and Disposing of a Route

When a route is added via #map or #proxy, a RouteUUID is returned. This RouteUUID can be used to dispose of the route.

```swift
routeUUID = router.map("routingexample://present/secret",
                       source: .Storyboard(storyboard: "Main", identifier: "SecretViewController", bundle: nil),
                       style: .InNavigationController(.Present(animated: true))) 
                               
router.disposeOf(routeUUID)
```

### Callback Queues

A queue may be passed to maps or proxies. This queue will be the queue that a RouteHandler or ProxyHandler closure is called back on. By default, maps that are used for view controller navigation are called back on the main queue.

```swift
let callbackQueue = dispatch_queue_create("Call Back Queue", DISPATCH_QUEUE_SERIAL) 
router.map("routingexample://route", queue: callbackQueue) { (_, _, _, completed) in
    completed()
}
```

### Presentation Setup

View controllers mapped to the router will have the opportunity to be informed of a opened route through either a closure or the RoutingPresentationSetup protocol. In either implementation, the view controller will have access to the parameters passed through the URL. An example of the closure approach is in the [Usage](#usage) section above. The protocol looks as follows.

```swift
class LoginViewController: UIViewController, RoutingPresentationSetup {
    var callback: String?
    
    func setup(route: String, parameters: Parameters, data: Data) {
        if let callbackURL = parameters["callback"] {
            self.callback = callbackURL
        }
        
        if let date = data as? NSDate {
            self.passedDate = date
        }
    }
}
```

### Presentation Styles

```swift
indirect public enum PresentationStyle {
    case Show
    case ShowDetail
    case Present(animated: Bool)
    case Push(animated: Bool)
    case Custom(custom: (presenting: UIViewController, presented: UIViewController, completed: Routing.Completed) -> Void)
    case InNavigationController(Routing.PresentationStyle)
}
```

The above presentation styles are made available. The recursive .InNavigationController(PresentationStyle) enumeration will result in the view controller being wrapped in a navigation controller before being presented in whatever fashion. There is also the ability to provide custom presentation styles.

### View Controller Sources

The following view controller sources are utilized.

```swift
public enum ControllerSource {
    case Storyboard(storyboard: String, identifier: String, bundle: NSBundle?)
    case Nib(controller: UIViewController.Type, name: String?, bundle: NSBundle?)
    case Provided(() -> UIViewController)
}
```

### Presentation Extensions

The following has been extended to allow for a completion closure to be passed in.

```swift
extension UIViewController {
    public func showViewController(vc: UIViewController, sender: AnyObject?, completion: Routing.Completed)
    public func showDetailViewController(vc: UIViewController, sender: AnyObject?, completion: Routing.Completed)
}

extension UINavigationController {
    public func pushViewController(vc: UIViewController, animated: Bool, completion: Routing.Completed)
    public func popViewControllerAnimated(animated: Bool, completion: Routing.Completed) -> UIViewController?
    public func popToViewControllerAnimated(viewController: UIViewController, animated: Bool, completion: Routing.Completed) -> [UIViewController]?
    public func popToRootViewControllerAnimated(animated: Bool, completion: Routing.Completed) -> [UIViewController]?
}
```
