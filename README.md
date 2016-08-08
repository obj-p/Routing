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

![Account Information](http://i.giphy.com/l46CadVdLgotxmqIM.gif | height = 100px)

Eventually we may need to support a user editting their account information on a website. After completing the process from a web browser, the site may deep link into the relevant screen within the mobile app. This can be handled in the AppDelegate simply as follows.

```swift
func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
    return router["Views"].open(url)
}
```

![Deep Link](http://i.giphy.com/3o6ZsW8YIdRnCK3172.gif | height = 100px)

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

pod 'Routing', '~> 0.4.2'
```

### Carthage

Via [Carthage](https://github.com/Carthage/Carthage):

```ogdl
github "jwalapr/Routing"
```
