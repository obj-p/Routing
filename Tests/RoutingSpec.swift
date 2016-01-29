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
            
            context("#registerHost") {
                // TODO: perhaps have a means to register a host component for the URL check in #open
            }
            
            context("#open") {
                
                it("should return true if it can open the route") {
                    router.map("/route") { (_, completed) in completed() }
                    
                    expect(router.open(NSURL(string: "routingexample://route/")!)).to(equal(true))
                }
                
                it("should return fales if it cannot open the route due to no routes registered") {
                    expect(router.open(NSURL(string: "routingexample://route/")!)).to(equal(false))
                }
                
                it("should return false if it cannot open the route due to no match") {
                    router.map("/route") { (_, completed) in completed() }
                    expect(router.open(NSURL(string: "routingexample://incorrectroute/")!)).to(equal(false))
                }
                
                it("should call the binded closure corresponding to the opened route") {
                    var isOpened = false
                    router.map("/route") { (_, completed) in
                        isOpened = true
                        completed()
                    }
                    
                    router.open(NSURL(string: "routingexample://route/")!)
                    expect(isOpened).toEventually(equal(true))
                }
                
                it("should pass url arguments specified in the route in the parameters dictionary") {
                    var argument: String?
                    router.map("/route/:argument") { (parameters, completed) in
                        argument = parameters["argument"]
                        completed()
                    }
                    
                    router.open(NSURL(string: "routingexample://route/expected")!)
                    expect(argument).toEventually(equal("expected"))
                }
                
                it("should pass query parameters specified in the route in the parameters dictionary") {
                    var param: String?
                    router.map("/route") { (parameters, completed) in
                        param = parameters["param"]
                        completed()
                    }
                    
                    router.open(NSURL(string: "routingexample://route?param=expected")!)
                    expect(param).toEventually(equal("expected"))
                }
                
                it("should process urls in a serial order") {
                    var results = [String]()
                    
                    router.map("/route/:append") { (parameters, completed) in
                        results.append(parameters["append"]!)
                        
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (1 * Int64(NSEC_PER_SEC))), testingQueue, completed)
                    }
                    
                    router.map("/route/two/:append") { (parameters, completed) in
                        results.append(parameters["append"]!)
                        completed()
                    }
                    
                    router.open(NSURL(string: "routingexample://route/one")!)
                    router.open(NSURL(string: "routingexample://route/two/two")!)
                    expect(results).toEventually(equal(["one", "two"]), timeout: 1.1, pollInterval: 0, description: nil)
                }
                
                it("should be able to open the route despite concurrent read right accesses") {
                    router.map("/route") { (_, completed) in completed() }
                    
                    dispatch_async(testingQueue) {
                        for i in 1...10000 {
                            router.map("\(i)") { (_, completed) in completed() }
                        }
                    }
                    
                    dispatch_async(testingQueue) {
                        for i in 1...10000 {
                            router.map("\(i)") { (_, completed) in completed() }
                        }
                    }
                    
                    expect(router.open(NSURL(string: "routingexample://route/")!)).toEventually(equal(true))
                }
                
            }
            
            context("#proxy") {
                it("should be able to proxy and modify the path") {
                    var pathCalled: UInt8 = 1
                    router.map("/route/one") { (_, completed) in completed()
                        pathCalled = pathCalled << 1
                    }
                    router.map("/route/two") { (_, completed) in completed()
                        pathCalled = pathCalled << 2
                    }
                    
                    router.proxy("/route/one") { (path, parameters, next) -> Void in
                        next("/route/two", parameters)
                    }
                    
                    router.open(NSURL(string: "routingexample://route/one")!)
                    expect(pathCalled).toEventually(equal(4))
                }
            }
            
        }
        
    }
    
}
