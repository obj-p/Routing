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
                    let route = "/route/"
                    var isOpened = false
                    Routing.sharedRouter.map(route) { (parameters) in
                        isOpened = true
                    }
                    
                    Routing.sharedRouter.open(NSURL(string: "routingexample://route/")!)
                    expect(isOpened).to(equal(true))
                }
                
            }
            
        }
        
    }
    
}
