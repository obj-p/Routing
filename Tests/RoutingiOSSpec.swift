//
//  RoutingiOSSpec.swift
//  Routing
//
//  Created by Jason Prasad on 2/19/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import XCTest
import Quick
import Nimble
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
                        identifier: "StoryboardViewController")
                    
                    expect(router.open(NSURL(string: "routingexample://route/")!)).to(equal(true))
                }
                
                it("should return true if it can open the route from nib") {
                    router.map("routingexample://route",
                        nib: "NibViewController")
                    
                    expect(router.open(NSURL(string: "routingexample://route/")!)).to(equal(true))
                }
                
                it("should return true if it can open the route from instance") {
                    router.map("routingexample://route", instance: { UIViewController() })
                    
                    expect(router.open(NSURL(string: "routingexample://route/")!)).to(equal(true))
                }
                
            }
            
            context("Show") {
                
            }
            
            context("Show Detail") {
                
            }
            
            context("Present") {
                
            }
            
            context("Push") {
                
            }
            
            context("Custom") {
                
            }
            
            context("Top is TabBar Controller") {
                
            }
            
            context("Top is Navigation Controller") {
                
            }

            context("Top is View Controller") {
                
            }
            
            context("Top is Childe View Controller") {
                
            }
            
        }
        
    }
    
}
