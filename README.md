# Routing

[![Build Status](https://travis-ci.org/jwalapr/Routing.svg?branch=master)](https://travis-ci.org/jwalapr/Routing)
[![Code coverage status](https://img.shields.io/codecov/c/github/jwalapr/Routing.svg?style=flat-square)](http://codecov.io/github/jwalapr/Routing)
[![Platform support](https://img.shields.io/badge/platform-ios%20%7C%20osx%20%7C%20tvos%20%7C%20watchos-lightgrey.svg?style=flat-square)](https://img.shields.io/badge/platform-ios%20%7C%20osx%20%7C%20tvos%20%7C%20watchos-lightgrey.svg?style=flat-square) 
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Routing.svg)](https://cocoapods.org/pods/Routing)
[![License MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://github.com/Routing/Routing/blob/master/LICENSE)

## Table of Contents

- [Usage](#usage)
- [Installation](#installation)
- [Further Detail](#further-detail)
- [Example](#example)

## Usage

Routing may be used to deep link and proxy view controller navigation or other actions.

To map a view controller transition is as simple as...

```swift
router.map("routingexample://route",
    instance: .Storyboard(storyboard: "Main", identifier: "ViewController", bundle: nil),
    style: .Push(animated: true))
```

To map a closure to be called...

```swift
router.map("routing://route") { route, parameters, completed in
	...
	completed() // Must call completed or the router will halt!
}
```

To proxy with a closure...

```swift
router.proxy("routing://route") { route, parameters, next in
	...
	next(route, parameters) // Must call next or the router will halt!
	/* alternatively, next(nil, nil) allowing additional proxies to execute */
}
```

And to open any string or URL...

```swift
// Each router.open(...) will return true / false
router.open("routing://route/") 
router.open(NSURL(string: "routing://route/")!) 
```

## Installation

### CocoaPods

Via [CocoaPods](https://cocoapods.org/pods/Routing):

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod 'Routing', '~> 0.2.2'
```

To specifiy a platform other than iOS use the following subspec

```ruby
pod 'Routing/Others', '~> 0.2.2'
```

### Carthage

Via [Carthage](https://github.com/Carthage/Carthage):

```ogdl
github "jwalapr/Routing"
```

## Further Detail

### Map (For View Controllers)

```swift
// Supports creation of view controller the following ways
public enum PresentedInstance {
    case Storyboard(storyboard: String, identifier: String, bundle: NSBundle?)
    case Nib(controller: UIViewController.Type, name: String?, bundle: NSBundle?)
    case Provided(() -> UIViewController)
}

// Supports the following view controller transitions
public enum PresentationStyle {   
    case Show
    case ShowDetail
    case Present(animated: Bool)
    case Push(animated: Bool)
    case Custom(custom: (presenting: UIViewController,
        presented: UIViewController,
        completed: Completed) -> Void)
}

router.map("routingexample://route",
    instance: .Storyboard(storyboard: "Main", identifier: "ViewController", bundle: nil),
    style: .Present(animated: true)) { vc, parameters in
        ... // Useful callback for setup such as embedding in navigation controller
        return vc
}
```

### Map

```swift
router.map("routing://route") { route, parameters, completed in
	...
	completed() // Must call completed or the router will halt!
}

router.map("routing://*") { ... } // Regex, wildcards are supported
router.map("routing://route/:id") { ... } // Dynamic segments are supported

let queue = dispatch_queue_create("Callback Queue", DISPATCH_QUEUE_SERIAL)
router.map("routing://route/", queue: queue) { ... } // Can specify callback queue
```

### Proxy

```swift
router.proxy("routing://route") { route, parameters, next in
	...
	next(route, parameters) // Must call next or the router will halt!
	/* alternatively, next(nil, nil) allowing additional proxies to execute */
}

router.proxy("routing://*") { ... } // Regex, wildcards are supported
router.proxy("routing://route/:id") { ... } // Dynamic segments are supported

let queue = dispatch_queue_create("Callback Queue", DISPATCH_QUEUE_SERIAL)
router.proxy("routing://route/", queue: queue) { ... } // Can specify callback queue
```

### Open

```swift
// Each router.open(...) will return true / false
router.open("routing://route/") 
router.open(NSURL(string: "routing://route/")!) 
router.open(NSURL(string: "routing://route/0123456789")!) // ex. route/:id
router.open(NSURL(string: "routing://route?foo=bar")!) // query paremeters will be passed to mapped closure.
```

## Example

An Example iOS app is provided to show how to use #map, #proxy, and #open in greater detail.
