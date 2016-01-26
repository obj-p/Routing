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

extension Routing {
    static var sharedRouter = { Routing() }()
}

class RoutingSpec: QuickSpec {
    
    override func spec() {
        
        describe("Routing") {
            
            context("#open") {
                
                it("should call the binded closure corresponding to the opened route") {
                    let route = "/route"
                    var isOpened = false
                    Routing.sharedRouter.map(route) { (parameters, completed) in
                        isOpened = true
                        completed()
                    }
                    
                    Routing.sharedRouter.open(NSURL(string: "routingexample://route/")!)
                    expect(isOpened).to(equal(true))
                }
                
                it("should pass url arguments specified in the route in the parameters dictionary") {
                    let route = "/route/:argument"
                    var argument: String?
                    Routing.sharedRouter.map(route) { (parameters, completed) in
                        argument = parameters["argument"]
                        completed()
                    }
                    
                    Routing.sharedRouter.open(NSURL(string: "routingexample://route/expected")!)
                    expect(argument).to(equal("expected"))
                }
                
                it("should pass query parameters specified in the route in the parameters dictionary") {
                    let route = "/route"
                    var param: String?
                    Routing.sharedRouter.map(route) { (parameters, completed) in
                        param = parameters["param"]
                        completed()
                    }
                    
                    Routing.sharedRouter.open(NSURL(string: "routingexample://route?param=expected")!)
                    expect(param).to(equal("expected"))
                }
                
            }
            
            context("#proxy") {
                
            }
            
        }
        
    }
    
}
