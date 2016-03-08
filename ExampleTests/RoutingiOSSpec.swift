//
//  RoutingiOSSpec.swift
//  iOS Example Tests
//
//  Created by Jason Prasad on 3/7/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import XCTest
import Quick
import Nimble
@testable import iOS_Example
@testable import Routing

class RoutingiOSSpec: QuickSpec {
    
    override func spec() {
        
        describe("RoutingiOS") {
            
            var router: Routing!
            beforeEach {
                router = Routing()
            }
            
            context("#open") {
                
                it("should return true if it can open the route from storyboard") {
                    router.map("routingexample://route",
                        storyboard: "Main",
                        identifier: "first")
                    
                    expect(router.open(NSURL(string: "routingexample://route/")!)).to(equal(true))
                }
                
                it("should return true if it can open the route from nib") {
//                    router.map("routingexample://route",
//                        nib: "First")
//                    
//                    expect(router.open(NSURL(string: "routingexample://route/")!)).to(equal(true))
                }
                
                it("should return true if it can open the route from instance") {
//                    router.map("routingexample://route", instance: { UIViewController() })
//                    
//                    expect(router.open(NSURL(string: "routingexample://route/")!)).to(equal(true))
                }
                
            }
            
            context("Show") {
                
                it("should show the view controller from storyboard") {
                    var isOpenend = false
                    router.map("routingexample://route",
                        storyboard: "Main",
                        identifier: "first",
                        bundle: NSBundle(identifier: "com.routing.iOS-Example")) { _, _ in
                            isOpenend = true
                    }
                    
                    router.open(NSURL(string: "routingexample://route/")!)
                    expect(isOpenend).toEventually(equal(true))
                }
            }
            
        }
        
    }
    
}