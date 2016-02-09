//
//  RoutingSpec.swift
//  RoutingSpec
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
                    router.map("routingexample://route") { (_, completed) in completed() }
                    
                    expect(router.open(NSURL(string: "routingexample://route/")!)).to(equal(true))
                }
                
                it("should return false if it cannot open the route due to no routes registered") {
                    expect(router.open(NSURL(string: "routingexample://route/")!)).to(equal(false))
                }
                
                it("should return false if it cannot open the route due to no match") {
                    router.map("routingexample://route") { (_, completed) in completed() }
                    expect(router.open(NSURL(string: "routingexample://incorrectroute/")!)).to(equal(false))
                }
                
                it("should call the binded closure corresponding to the opened route") {
                    var isOpened = false
                    router.map("routingexample://route") { (_, completed) in
                        isOpened = true
                        completed()
                    }
                    
                    router.open(NSURL(string: "routingexample://route")!)
                    expect(isOpened).toEventually(equal(true))
                }
                
                it("should call the latest closure binded to the route") { 
                    var routeCalled: UInt8 = 1
                    router.map("routingexample://route") { (_, completed) in
                        routeCalled = routeCalled << 1
                        completed()
                    }
                    
                    router.map("routingexample://route") { (_, completed) in
                        routeCalled = routeCalled << 2
                        completed()
                    }
                    
                    router.open(NSURL(string: "routingexample://route")!)
                    expect(routeCalled).toEventually(equal(4))
                }
                
                it("should pass url arguments specified in the route in the parameters dictionary") {
                    var argument: String?
                    router.map("routingexample://route/:argument/:argument2") { (parameters, completed) in
                        argument = parameters["argument"]
                        completed()
                    }
                    
                    router.open(NSURL(string: "routingexample://route/expected/expected2")!)
                    expect(argument).toEventually(equal("expected"))
                }
                
                it("should pass query parameters specified in the route in the parameters dictionary") {
                    var param: String?
                    router.map("routingexample://route") { (parameters, completed) in
                        param = parameters["param"]
                        completed()
                    }
                    
                    router.open(NSURL(string: "routingexample://route?param=expected")!)
                    expect(param).toEventually(equal("expected"))
                }
                
                it("should process urls in a serial order") {
                    var results = [String]()
                    
                    router.map("routingexample://route/:append") { (parameters, completed) in
                        results.append(parameters["append"]!)
                        
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (1 * Int64(NSEC_PER_SEC))), testingQueue, completed)
                    }
                    
                    router.map("routingexample://route/two/:append") { (parameters, completed) in
                        results.append(parameters["append"]!)
                        completed()
                    }
                    
                    router.open(NSURL(string: "routingexample://route/one")!)
                    router.open(NSURL(string: "routingexample://route/two/two")!)
                    expect(results).toEventually(equal(["one", "two"]), timeout: 1.5)
                }
                
                it("should be able to open the route despite concurrent read right accesses") {
                    router.map("routingexample://route") { (_, completed) in completed() }
                    
                    dispatch_async(testingQueue) {
                        for i in 1...1000 {
                            router.map("\(i)") { (_, completed) in completed() }
                        }
                    }
                    
                    dispatch_async(testingQueue) {
                        for i in 1...1000 {
                            router.map("\(i)") { (_, completed) in completed() }
                        }
                    }
                    
                    expect(router.open(NSURL(string: "routingexample://route")!)).toEventually(equal(true))
                }

                it("should allow to set the callback queue of the route") {
                    let callbackQueue = dispatch_queue_create("Testing Call Back Queue", DISPATCH_QUEUE_SERIAL)
                    let expectedQueue: UnsafePointer<Int8> = dispatch_queue_get_label(callbackQueue)
                    
                    var actualQueue: UnsafePointer<Int8>?
                    router = Routing(callbackQueue: callbackQueue)
                    router.map("routingexample://route") { (_, completed) in
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
                    router.map("routingexample://route/one") { (_, completed) in completed()
                        routeCalled = routeCalled << 1
                    }
                    router.map("routingexample://route/two") { (_, completed) in completed()
                        routeCalled = routeCalled << 2
                    }
                    
                    router.proxy("routingexample://route/one") { (route, parameters, next) -> Void in
                        next("routingexample://route/two", parameters)
                    }
                    
                    router.open(NSURL(string: "routingexample://route/one")!)
                    expect(routeCalled).toEventually(equal(4))
                }
                
                xit("should allow for wild card / regex matching") {
                    router.map("/route/one") { (_, completed) in completed() }
                    
                    var isProxied = false
                    router.proxy("/route/*") { (route, parameters, next) -> Void in
                        isProxied = true
                    }
                    
                    router.open(NSURL(string: "routingexample://route/one")!)
                    expect(isProxied).toEventually(equal(true))
                }
                
                it("should allow for modifying arguments passed in url") {
                    var argument: String?
                    router.map("routingexample://route/:argument") { (parameters, completed) in
                        argument = parameters["argument"]
                        completed()
                    }
                    
                    router.proxy("routingexample://route/:argument") { (route, var parameters, next) -> Void in
                        parameters["argument"] = "two"
                        next(route, parameters)
                    }
                    
                    router.open(NSURL(string: "routingexample://route/one")!)
                    expect(argument).toEventually(equal("two"))
                }
                
                it("should allow for modifying query parameters passed in url") {
                    var query: String?
                    router.map("routingexample://route") { (parameters, completed) in
                        query = parameters["query"]
                        completed()
                    }
                    
                    router.proxy("routingexample://route") { (route, var parameters, next) -> Void in
                        parameters["query"] = "bar"
                        next(route, parameters)
                    }
                    
                    router.open(NSURL(string: "routingexample://route?query=foo")!)
                    expect(query).toEventually(equal("bar"))
                }
                
                it("should process multiple proxies in a serial order") {
                    router.map("routingexample://route") { (parameters, completed) in completed() }
                    
                    var results = [String]()
                    router.proxy("routingexample://route") { (route, parameters, next) in
                        results.append("two")
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (1 * Int64(NSEC_PER_SEC))), testingQueue) {
                            next(route, parameters)
                        }
                    }
                    
                    router.proxy("routingexample://route") { (route, parameters, next) in
                        results.append("one")
                        next(route, parameters)
                    }
                    
                    router.open(NSURL(string: "routingexample://route")!)
                    expect(results).toEventually(equal(["one", "two"]), timeout: 1.5)
                }
                
                it("should be able to open the route despite concurrent read right accesses") {
                    router.map("routingexample://route") { (_, completed) in completed() }
                    
                    dispatch_async(testingQueue) {
                        for i in 1...1000 {
                            router.proxy("\(i)") { (route, parameters, next) in next(route, parameters) }
                        }
                    }
                    
                    dispatch_async(testingQueue) {
                        for i in 1...1000 {
                            router.proxy("\(i)") { (route, parameters, next) in next(route, parameters) }
                        }
                    }
                    
                    expect(router.open(NSURL(string: "routingexample://route")!)).toEventually(equal(true))
                }
                
                it("should maintain the parameters throughout the proxy and the mapped route") {
                    var proxiedArgument, proxiedQuery: String?
                    router.proxy("routingexample://route/:argument") { (route, parameters, next) in
                        (proxiedArgument, proxiedQuery) = (parameters["argument"], parameters["query"])
                        next(route, parameters)
                    }
                    
                    var argument, query: String?
                    router.map("routingexample://route/:argument") { (parameters, completed) in
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
                    
                    router = Routing(callbackQueue: callbackQueue)
                    router.map("routingexample://route") { (_, completed) in completed() }
                    
                    var actualQueue: UnsafePointer<Int8>?
                    router.proxy("routingexample://route") { (route, parameters, next) in
                        actualQueue = dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL)
                        next(route, parameters)
                    }
                    
                    router.open(NSURL(string: "routingexample://route")!)
                    expect(actualQueue).toEventually(equal(expectedQueue))
                }
                
            }
            
        }
        
    }
    
}
