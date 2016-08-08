# Routing

[![Build Status](https://travis-ci.org/jwalapr/Routing.svg?branch=master)](https://travis-ci.org/jwalapr/Routing)
[![Code coverage status](https://img.shields.io/codecov/c/github/jwalapr/Routing.svg?style=flat-square)](http://codecov.io/github/jwalapr/Routing)
[![Platform support](https://img.shields.io/badge/platform-ios%20%7C%20osx%20%7C%20tvos%20%7C%20watchos-lightgrey.svg?style=flat-square)](https://img.shields.io/badge/platform-ios%20%7C%20osx%20%7C%20tvos%20%7C%20watchos-lightgrey.svg?style=flat-square) 
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Routing.svg)](https://cocoapods.org/pods/Routing)
[![License MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://github.com/Routing/Routing/blob/master/LICENSE)

## Usage

Let's say you have a table view controller that displays account information once a user selects a cell. An implementation of tableView:didSelectRowAtIndexPath: may look as such.

```swift
override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    switch Row(rawValue: indexPath.row)! {
    // ...
    case .AccountInfo:
        router["Views"].open("routingexample://push/accountinfo")
    }
    // ...
}
```

Perhaps the account information is only available after a user authenticates with the service. After logging in we want the account information presented to the user right away. Without changing the above implementation we may proxy the intent and display a log in view, after which, a call back may present the original account information screen.

```swift
router.proxy("/*/accountinfo", tags: ["Views"]) { route, parameters, next in
    if authenticated {
        next(nil, nil)
    } else {
        next("routingexample://present/login?callback=\(route)", parameters)
    }
}
```

![Account Information](http://i.giphy.com/l0HlDRBupwd9z4wq4.gif)

Eventually we may need to support a user editting their account information on a website. After completing the process from a web browser, the site may deep link into the relevant screen within the mobile app. This can be handled in the AppDelegate simply as follows.

```swift
func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
    return router["Views"].open(url)
}
```

![Deep Link](http://i.giphy.com/3o7TKIGLGQYT6aHp5u.gif)

An example of other routes in an application may look like this.

```swift
let presentationSetup: PresentationSetup = { vc, _ in
    vc.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, 
                                                          target: vc, 
                                                          action: #selector(vc.cancel))
}

router.map("routingexample://present/login",
           source: .Storyboard(storyboard: "Main", identifier: "LoginViewController", bundle: nil),
           style: .InNavigationController(.Present(animated: true)),
           setup: presentationSetup)
    
router.map("routingexample://push/accountinfo",
           source: .Storyboard(storyboard: "Main", identifier: "AccountInfoViewController", bundle: nil),
           style: .Push(animated: true))
    
router.map("routingexample://present/settings",
           source: .Storyboard(storyboard: "Main", identifier: "SettingsViewController", bundle: nil),
           style: .InNavigationController(.Present(animated: true)),
           setup: presentationSetup)
    
router.proxy("/*", tags: ["Views"]) { route, parameters, next in
    print("opened: route (\(route)) with parameters (\(parameters))")
    next(nil, nil)
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

pod 'Routing', '~> 1.0.0'
```

### Carthage

Via [Carthage](https://github.com/Carthage/Carthage):

```ogdl
github "jwalapr/Routing"
```
## Further Detail

### Map

A router instance may map a string pattern to view controller navigation as covered above or just a closure as presented below. The closure will have three parameters. The route it matched, the parameters (both query and segments in the URL), and a completion closure that must be called or the router will halt all subsequent calls to #open.

```swift
router.map("routingexample://route/:argument") { route, parameters, completed in
    argument = parameters["argument"]
    completed()
}
```

### Proxy

A router instance may proxy any string pattern. The closure will also have three parameters. The route it matched, the parameters, and a next closure. The next closure accepts two optional arguments for the route and parameters. If nil is passed to both arguments then the router will continue to another proxy if it exists or subsequently to a mapped route. If a proxy were to pass a route or parameters to the next closure, the router will skip any subsequent proxy and attempt to match a mapped route. Failure to call next will halt the router and all subsequent calls to #open. 

```swift
router.proxy("routingexample://route/one") { (route, parameters, next) -> Void in
    next("routingexample://route/two", parameters)
}
```

### Order of Map or Proxy

In general, the last call to register a map or proxy to the router will be first called in the event of a matched URL respectively. Proxies will be serviced first and then a map.

### Tags

A tag may be passed to maps or proxies. The default tag for maps to view controller navigation is "Views". Tags allow for the router to be subscripted to a specific context. If a router is subscripted with "Views", then it will only attempt to find routes that are tagged as such.

```swift
router["Views", "Logs", "Actions"].open(url)
```

### Callback Queues

A queue may be passed to maps or proxies. This queue will be the queue that a RouteHandler or ProxyHandler closure is called back on. By default, maps that are used for view controller navigation are called back on the main queue.

```swift
let callbackQueue = dispatch_queue_create("Testing Call Back Queue", DISPATCH_QUEUE_SERIAL) 
router.map("routingexample://route", queue: callbackQueue) { (_, _, completed) in
    completed()
}
```