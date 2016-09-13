//
//  RoutingSpec.swift
//  Routing
//
//  Created by Jason Prasad on 9/28/15.
//  Copyright © 2015 Routing. All rights reserved.
//

import XCTest
import Quick
import Nimble
@testable import Routing

class RoutingSpec: QuickSpec {
    
    override func spec() {
        
        describe("Routing") {
            
            var router: Routing!
            var testingQueue: dispatch_queue_t!
            beforeEach {
                router = Routing()
                testingQueue = dispatch_queue_create("Testing Queue", DISPATCH_QUEUE_CONCURRENT)
            }
            
            context("#open") {
                
                it("should return true if it can open the route") {
                    router.map("routingexample://route") { (_, _, _, completed) in completed() }
                    
                    expect(router.open(NSURL(string: "routingexample://route/")!)).to(equal(true))
                }
                
                it("should return false if it cannot open the route due to no routes registered") {
                    expect(router.open(NSURL(string: "routingexample://route/")!)).to(equal(false))
                }
                
                it("should return false if it cannot open the route due to no match") {
                    router.map("routingexample://route") { (_, _, _, completed) in completed() }
                    expect(router.open(NSURL(string: "routingexample://incorrectroute/")!)).to(equal(false))
                }
                
                it("should call the binded closure corresponding to the opened route") {
                    var isOpened = false
                    router.map("routingexample://route") { (_, _, _, completed) in
                        isOpened = true
                        completed()
                    }
                    
                    router.open(NSURL(string: "routingexample://route")!)
                    expect(isOpened).toEventually(equal(true))
                }
                
                it("should call the latest closure binded to the route") { 
                    var routeCalled: UInt8 = 1
                    router.map("routingexample://route") { (_, _, _, completed) in
                        routeCalled = routeCalled << 1
                        completed()
                    }
                    
                    router.map("routingexample://route") { (_, _, _, completed) in
                        routeCalled = routeCalled << 2
                        completed()
                    }
                    
                    router.open(NSURL(string: "routingexample://route")!)
                    expect(routeCalled).toEventually(equal(4))
                }
                
                it("should pass the matching route to the closure") {
                    var matched: String?
                    router.map("routingexample://route") { (route, _, _, completed) in
                        matched = route
                        completed()
                    }
                    
                    router.open(NSURL(string: "routingexample://route")!)
                    expect(matched).toEventually(equal("routingexample://route"))
                }
                
                it("should pass url arguments specified in the route in the parameters dictionary") {
                    var argument: String?
                    router.map("routingexample://route/:argument") { (_, parameters, _, completed) in
                        argument = parameters["argument"]
                        completed()
                    }
                    
                    router.open(NSURL(string: "routingexample://route/expected")!)
                    expect(argument).toEventually(equal("expected"))
                }
                
                it("should pass query parameters specified in the route in the parameters dictionary") {
                    var param: String?
                    router.map("routingexample://route") { (_, parameters, _, completed) in
                        param = parameters["param"]
                        completed()
                    }
                    
                    router.open(NSURL(string: "routingexample://route?param=expected")!)
                    expect(param).toEventually(equal("expected"))
                }
                
                it("should process urls in a serial order") {
                    var results = [String]()
                    
                    router.map("routingexample://route/:append") { (_, parameters, _, completed) in
                        results.append(parameters["append"]!)
                        
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (1 * Int64(NSEC_PER_SEC))), testingQueue, completed)
                    }
                    
                    router.map("routingexample://route/two/:append") { (_, parameters, _, completed) in
                        results.append(parameters["append"]!)
                        completed()
                    }
                    
                    router.open(NSURL(string: "routingexample://route/one")!)
                    router.open(NSURL(string: "routingexample://route/two/two")!)
                    expect(results).toEventually(equal(["one", "two"]), timeout: 1.5)
                }
                
                it("should be able to open the route despite concurrent read right accesses") {
                    router.map("routingexample://route") { (_, _, _, completed) in completed() }
                    
                    dispatch_async(testingQueue) {
                        for i in 1...1000 {
                            router.map("\(i)") { (_, _, _, completed) in completed() }
                        }
                    }
                    
                    dispatch_async(testingQueue) {
                        for i in 1...1000 {
                            router.map("\(i)") { (_, _, _, completed) in completed() }
                        }
                    }
                    
                    expect(router.open(NSURL(string: "routingexample://route")!)).toEventually(equal(true))
                }

                it("should allow to set the callback queue of the route") {
                    let callbackQueue = dispatch_queue_create("Testing Call Back Queue", DISPATCH_QUEUE_SERIAL)
                    let expectedQueue: UnsafePointer<Int8> = dispatch_queue_get_label(callbackQueue)
                    
                    var actualQueue: UnsafePointer<Int8>?
                    router.map("routingexample://route", queue: callbackQueue) { (_, _, _, completed) in
                        actualQueue = dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL)
                        completed()
                    }
                    
                    router.open(NSURL(string: "routingexample://route")!)
                    expect(actualQueue).toEventually(equal(expectedQueue))
                }
                
            }
            
            context("#proxy") {
                
                it("should be able to proxy and modify the route") {
                    var routeCalled: UInt8 = 1
                    router.map("routingexample://route/one") { (_, _, _, completed) in completed()
                        routeCalled = routeCalled << 1
                    }
                    router.map("routingexample://route/two") { (_, _, _, completed) in completed()
                        routeCalled = routeCalled << 2
                    }
                    
                    router.proxy("routingexample://route/one") { (route, parameters, data, next) -> Void in
                        next("routingexample://route/two", parameters, data)
                    }
                    
                    router.open(NSURL(string: "routingexample://route/one")!)
                    expect(routeCalled).toEventually(equal(4))
                }
                
                it("should allow for wild card / regex matching") {
                    router.map("/route/one") { (_, _, _, completed) in completed() }
                    
                    var isProxied = false
                    router.proxy("/route/*") { (route, parameters, _, next) -> Void in
                        isProxied = true
                    }
                    
                    router.open(NSURL(string: "routingexample://route/one")!)
                    expect(isProxied).toEventually(equal(true))
                }
                
                it("should allow for modifying arguments passed in url") {
                    var argument: String?
                    router.map("routingexample://route/:argument") { (_, parameters, _, completed) in
                        argument = parameters["argument"]
                        completed()
                    }
                    
                    router.proxy("routingexample://route/:argument") { (route, parameters, data, next) -> Void in
                        var parameters = parameters
                        parameters["argument"] = "two"
                        next(route, parameters, data)
                    }
                    
                    router.open(NSURL(string: "routingexample://route/one")!)
                    expect(argument).toEventually(equal("two"))
                }
                
                it("should allow for modifying query parameters passed in url") {
                    var query: String?
                    router.map("routingexample://route") { (_, parameters, _, completed) in
                        query = parameters["query"]
                        completed()
                    }
                    
                    router.proxy("routingexample://route") { (route, parameters, data, next) -> Void in
                        var parameters = parameters
                        parameters["query"] = "bar"
                        next(route, parameters, data)
                    }
                    
                    router.open(NSURL(string: "routingexample://route?query=foo")!)
                    expect(query).toEventually(equal("bar"))
                }
                
                it("should continue processing proxies until a proxy to passes a route back") {
                    router.map("routingexample://route") { (_, parameters, _, completed) in completed() }
                    
                    var results = [String]()
                    router.proxy("routingexample://route") { (route, parameters, _, next) in
                        results.append("three")
                        next(nil, nil, nil)
                    }
                    
                    router.proxy("routingexample://route") { (route, parameters, _, next) in
                        results.append("two")
                        next(route, nil, nil)
                    }
                    
                    router.proxy("routingexample://route") { (route, parameters, _, next) in
                        results.append("one")
                        next(nil, nil, nil)
                    }
                    
                    router.open(NSURL(string: "routingexample://route")!)
                    expect(results).toEventually(equal(["one", "two"]))
                }
                
                it("should continue processing proxies until a proxy to passes parameters back") {
                    router.map("routingexample://route") { (_, parameters, _, completed) in completed() }
                    
                    var results = [String]()
                    router.proxy("routingexample://route") { (route, parameters, _, next) in
                        results.append("three")
                        next(nil, nil, nil)
                    }
                    
                    router.proxy("routingexample://route") { (route, parameters, data, next) in
                        results.append("two")
                        next(nil, parameters, nil)
                    }
                    
                    router.proxy("routingexample://route") { (route, parameters, _, next) in
                        results.append("one")
                        next(nil, nil ,nil)
                    }
                    
                    router.open(NSURL(string: "routingexample://route")!)
                    expect(results).toEventually(equal(["one", "two"]))
                }
                
                it("should be able to open the route despite concurrent read right accesses") {
                    router.map("routingexample://route") { (_, _, _, completed) in completed() }
                    
                    dispatch_async(testingQueue) {
                        for i in 1...1000 {
                            router.proxy("\(i)") { (route, parameters, data, next) in next(route, parameters, data) }
                        }
                    }
                    
                    dispatch_async(testingQueue) {
                        for i in 1...1000 {
                            router.proxy("\(i)") { (route, parameters, data, next) in next(route, parameters, data) }
                        }
                    }
                    
                    expect(router.open(NSURL(string: "routingexample://route")!)).toEventually(equal(true))
                }
                
                it("should maintain the parameters throughout the proxy and the mapped route") {
                    var proxiedArgument, proxiedQuery: String?
                    router.proxy("routingexample://route/:argument") { (route, parameters, data, next) in
                        (proxiedArgument, proxiedQuery) = (parameters["argument"], parameters["query"])
                        next(route, parameters, data)
                    }
                    
                    var argument, query: String?
                    router.map("routingexample://route/:argument") { (_, parameters, _, completed) in
                        (argument, query) = (parameters["argument"], parameters["query"])
                        completed()
                    }
                    
                    router.open(NSURL(string: "routingexample://route/foo?query=bar")!)
                    expect(proxiedArgument).toEventually(equal("foo"))
                    expect(argument).toEventually(equal("foo"))
                    expect(proxiedQuery).toEventually(equal("bar"))
                    expect(query).toEventually(equal("bar"))
                }
                
                it("should allow to set the callback queue of the proxy") {
                    let callbackQueue = dispatch_queue_create("Testing Callback Queue", DISPATCH_QUEUE_SERIAL)
                    let expectedQueue: UnsafePointer<Int8> = dispatch_queue_get_label(callbackQueue)
                    
                    router.map("routingexample://route") { (_, _, _, completed) in completed() }
                    
                    var actualQueue: UnsafePointer<Int8>?
                    router.proxy("routingexample://route", queue: callbackQueue) { (route, parameters, data, next) in
                        actualQueue = dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL)
                        next(route, parameters, data)
                    }
                    
                    router.open(NSURL(string: "routingexample://route")!)
                    expect(actualQueue).toEventually(equal(expectedQueue))
                }
                
            }
            
        }
        
    }
    
}
