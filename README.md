# Routing

[![Build Status](https://travis-ci.org/jwalapr/Routing.svg?branch=master)](https://travis-ci.org/jwalapr/Routing)
[![Code coverage status](https://img.shields.io/codecov/c/github/jwalapr/Routing.svg?style=flat-square)](http://codecov.io/github/jwalapr/Routing)
[![Platform support](https://img.shields.io/badge/platform-ios-lightgrey.svg?style=flat-square)](https://img.shields.io/badge/platform-ios-lightgrey.svg?style=flat-square) 
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Routing.svg)](https://img.shields.io/cocoapods/v/Routing.svg)
[![License MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://github.com/Routing/Routing/blob/master/LICENSE)

## Table of Contents

- [Usage](#usage)
- [Installation](#installation)
- [Example](#example)

## Usage

Routing associates string patterns to closures. In the event a URL opened by Routing matches a mapped string pattern, its associated closure will be executed. Opened URLs may also be proxied allowing for the addition of middleware.

### Map

```swift
let router = Routing()
router.map("routing://route") { parameters, completed in
	...
	completed() // Must call completed or the router will halt!
}

router.map("routing://*") { ... } // Regex, wildcards are supported
router.map("routing://route/:id") { ... } // Dynamic segments are supported
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
```

### Open

```swift
// Each router.open(...) will return true / false
router.open(NSURL(string: "routing://route/")!) 
router.open(NSURL(string: "routing://route/0123456789")!) // ex. route/:id
router.open(NSURL(string: "routing://route?foo=bar")!) // query paremeters will be passed to mapped closure.
```

## Installation

### CocoaPods

Via [CocoaPods](https://cocoapods.org):

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!

pod 'Routing', '~> 0.0.1'
```

### Carthage

Via [Carthage](https://github.com/Carthage/Carthage):

```ogdl
github "jwalapr/Routing"
```

## Example

An example app may be run with the Example scheme to demonstrate how Routing may be used for in app navigation.
