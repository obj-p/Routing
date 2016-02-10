# Routing

[![Build Status](https://travis-ci.org/jwalapr/Routing.svg?branch=master)](https://travis-ci.org/jwalapr/Routing)
[![Code coverage status](https://img.shields.io/codecov/c/github/jwalapr/Routing.svg?style=flat-square)](http://codecov.io/github/jwalapr/Routing)
[![Platform support](https://img.shields.io/badge/platform-ios-lightgrey.svg?style=flat-square)](https://github.com/ReSwift/ReSwift/blob/master/LICENSE.md) 
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://github.com/ReSwift/ReSwift/blob/master/LICENSE.md)

# Table of Contents

- [About Routing](#about-routing)
- [Installation](#installation)
- [Example](#example)

# Usage

## Map
```swift
let router = Routing()
router.map("/route") { parameters, completed in
	...
	completed() // Must call completed or the router will halt!
}
```

## Proxy
```swift
router.proxy("/route") { route, parameters, next in
	...
	next(route, parameters) // Must call next or the router will halt!
	/* or next(nil, nil) will allow additional proxies to execute */
	
}
```

## Open
```swift
router.open(NSURL(string: "host://route/")!) // Will return true or false if there is an associated route
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
