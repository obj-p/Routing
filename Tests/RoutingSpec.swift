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
            beforeEach {
                router = Routing()
            }
            
            context("#open") {
                
                it("should call the binded closure corresponding to the opened route") {
                    var isOpened = false
                    router.map("/route") { (parameters, completed) in
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
                        
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (1 * Int64(NSEC_PER_SEC))), dispatch_queue_create("Serial Test", nil), completed)
                    }
                    
                    router.map("/route/two/:append") { (parameters, completed) in
                        results.append(parameters["append"]!)
                        completed()
                    }
                    
                    router.open(NSURL(string: "routingexample://route/one")!)
                    router.open(NSURL(string: "routingexample://route/two/two")!)
                    expect(results).toEventually(equal(["one", "two"]), timeout: 1.1, pollInterval: 1.1, description: nil)
                }
                
            }
            
            context("#proxy") {
                
            }
            
        }
        
    }
    
}
