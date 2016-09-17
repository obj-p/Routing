//
//  RoutingTests.swift
//  Routing
//
//  Created by Jason Prasad on 9/17/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import XCTest
@testable import Routing

class RoutingOpenTests: XCTestCase {
    
    var router: Routing!
    var testingQueue: DispatchQueue!
    override func setUp() {
        super.setUp()
        router = Routing()
        testingQueue = DispatchQueue(label: "Testing Queue", attributes: DispatchQueue.Attributes.concurrent)
    }
    
    func testReturnsTrueIfItCanOpenURL() {
        router.map("routingexample://route") { (_, _, _, completed) in completed() }
        
        XCTAssertTrue(router.open(URL(string: "routingexample://route/")!))
    }
    
    func testReturnsTrueIfItCanOpenString() {
        router.map("routingexample://route") { (_, _, _, completed) in completed() }
        
        XCTAssertTrue(router.open("routingexample://route/"))
    }
    
    func testReturnsFalseIfItCannotOpenURL() {
        XCTAssertFalse(router.open(URL(string: "routingexample://incorrectroute/")!))
    }
    
    func testReturnsFalseIfItCannotOpenString() {
        XCTAssertFalse(router.open("routingexample://incorrectroute/"))
    }
    
    func testRouteHandlerIsCalled() {
        let expect = expectation(description: "RouteHandler is called.")
        router.map("routingexample://route") { (_, _, _, completed) in
            expect.fulfill()
            completed()
        }
        
        router.open("routingexample://route")
        waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    func testOnlyLatestAddedRouteHandlerIsCalled() {
        let expect = expectation(description: "Only latest #mapped RouteHandler is called.")
        
        var routeCalled = 0
        router.map("routingexample://route") { (_, _, _, completed) in
            routeCalled = 1
            expect.fulfill()
            completed()
        }
        
        router.map("routingexample://route") { (_, _, _, completed) in
            routeCalled = 2
            expect.fulfill()
            completed()
        }

        router.open("routingexample://route")
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssert(routeCalled == 2)
    }
    
    func testMatchingRouteStringPassedToRouteHandler() {
        let expect = expectation(description: "Route string is passed to RouteHandler.")
        
        var matched: String?
        router.map("routingexample://route") { (route, _, _, completed) in
            matched = route
            expect.fulfill()
            completed()
        }
        
        router.open("routingexample://route")
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssert(matched == "routingexample://route")
    }
    
    func testURLArgumentsArePassedToRouteHandler() {
        let expect = expectation(description: "URL Arguments are passed to RouteHandler.")
        var argument: String?
        router.map("routingexample://route/:argument") { (_, parameters, _, completed) in
            argument = parameters["argument"]
            expect.fulfill()
            completed()
        }
        
        router.open("routingexample://route/expected")
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssert(argument == "expected")
    }
    
    func testQueryParametersArePassedToRouteHandler() {
        let expect = expectation(description: "Query param is passed to RouteHandler.")
        
        var param: String?
        router.map("routingexample://route") { (_, parameters, _, completed) in
            param = parameters["param"]
            expect.fulfill()
            completed()
        }
        
        router.open("routingexample://route?param=expected")
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssert(param == "expected")
    }
    
    func testRouteHandlersAreCalledInSerialOrder() {
        let expect = expectation(description: "RouteHandlers are called in serial order.")
        
        var results = [String]()
        router.map("routingexample://route/:append") { (_, parameters, _, completed) in
            results.append(parameters["append"]!)
            
            self.testingQueue.asyncAfter(deadline: .now() + 1) {
                completed()
            }
        }
        
        router.map("routingexample://route/two/:append") { (_, parameters, _, completed) in
            results.append(parameters["append"]!)
            expect.fulfill()
            completed()
        }
        
        router.open(URL(string: "routingexample://route/one")!)
        router.open(URL(string: "routingexample://route/two/two")!)
        waitForExpectations(timeout: 1.5, handler: nil)
        XCTAssert(results == ["one", "two"])
    }
    
    func testRouterIsAbleToOpenDespiteConcurrentReadWriteAccesses() {
        
    }
    
}
