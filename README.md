# Routing

[![Build Status](https://travis-ci.org/jwalapr/Routing.svg?branch=master)](https://travis-ci.org/jwalapr/Routing)
[![Code coverage status](https://img.shields.io/codecov/c/github/jwalapr/Routing.svg?style=flat-square)](http://codecov.io/github/jwalapr/Routing)
[![Platform support](https://img.shields.io/badge/platform-ios-lightgrey.svg?style=flat-square)](https://github.com/ReSwift/ReSwift/blob/master/LICENSE.md) 
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://github.com/ReSwift/ReSwift/blob/master/LICENSE.md)

# Table of Contents

- [Usage](#usage)
- [Installation](#installation)
- [Example](#example)

# Usage

Routing allows for closures to be associated with a string pattern. 

## Map
```swift
let router = Routing()
router.map("routing://route") { parameters, completed in
	...
	completed() // Must call completed or the router will halt!
}

// Regex, wildcards are supported
router.map("routing://*") { ... } 
// Dynamic segments are supported
router.map("routing://route/:id") { ... }
```

## Proxy
```swift
router.proxy("routing://route") { route, parameters, next in
	...
	next(route, parameters) // Must call next or the router will halt!
	/* or next(nil, nil) will allow additional proxies to execute */
	
}
```

## Open
```swift
router.open(NSURL(string: "routing://route/")!) 
router.open(NSURL(string: "routing://route/0123456789")!) // ex. route/:id
router.open(NSURL(string: "routing://route?foo=bar")!)
```

# Installation

## Cocoapods
soon!

## Carthage
Via [Carthage](https://github.com/Carthage/Carthage):

```swift
github "jwalapr/ReSwift"
```

# Example
