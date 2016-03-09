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
            
            context("#open") {
                
                xit("should return true if it can open the route from storyboard") {}
                
                xit("should return true if it can open the route from nib") {}
                
                xit("should return true if it can open the route from instance") {}
                
            }
            
            context("Show") {
                
                xit("should show the view controller from storyboard") {}
                
            }
            
        }
        
    }
    
}