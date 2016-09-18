//
//  RoutingTests.swift
//  Routing
//
//  Created by Jason Prasad on 9/17/16.
//  Copyright © 2016 Routing. All rights reserved.
//

import XCTest
@testable import Routing

class RoutingMapTests: XCTestCase {
    var router: Routing!
    var testingQueue: DispatchQueue!
    override func setUp() {
        super.setUp()
        router = Routing()
        testingQueue = DispatchQueue(label: "Testing Queue", attributes: DispatchQueue.Attributes.concurrent)
    }
    
    func testReturnsTrueIfItCanOpenURL() {
        router.map("routingexample://route") { _, _, _, completed in completed() }
        
        XCTAssertTrue(router.open(URL(string: "routingexample://route/")!))
    }
    
    func testReturnsTrueIfItCanOpenString() {
        router.map("routingexample://route") { _, _, _, completed in completed() }
        
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
        router.map("routingexample://route") { _, _, _, completed in
            expect.fulfill()
            completed()
        }
        
        router.open("routingexample://route")
        waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    func testOnlyLatestAddedRouteHandlerIsCalled() {
        let expect = expectation(description: "Only latest #mapped RouteHandler is called.")
        
        var routeCalled = 0
        router.map("routingexample://route") { _, _, _, completed in
            routeCalled = 1
            expect.fulfill()
            completed()
        }
        
        router.map("routingexample://route") { _, _, _, completed in
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
        router.map("routingexample://route") { route, _, _, completed in
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
        router.map("routingexample://route/:argument") { _, parameters, _, completed in
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
        router.map("routingexample://route") { _, parameters, _, completed in
            param = parameters["param"]
            expect.fulfill()
            completed()
        }
        
        router.open("routingexample://route?param=expected")
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssert(param == "expected")
    }
    
    func testAnyCanBePassedToRouteHandler() {
        let expect = expectation(description: "Any is passed to RouteHandler.")
        
        var passed: Any?
        router.map("routingexample://route") { _, _, any, completed in
            passed = any
            expect.fulfill()
            completed()
        }
        
        router.open("routingexample://route", passing: "any")
        waitForExpectations(timeout: 0.1, handler: nil)
        if let passed = passed as? String {
            XCTAssert(passed == "any")
        } else {
            XCTFail()
        }
    }
    
    func testRouteHandlersAreCalledInSerialOrder() {
        let expect = expectation(description: "RouteHandlers are called in serial order.")
        
        var results = [String]()
        router.map("routingexample://route/:append") { _, parameters, _, completed in
            results.append(parameters["append"]!)
            
            self.testingQueue.asyncAfter(deadline: .now() + 1) {
                completed()
            }
        }
        
        router.map("routingexample://route/two/:append") { _, parameters, _, completed in
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
        router.map("routingexample://route") { _, _, _, completed in completed() }
        
        testingQueue.async {
            for i in 1...1000 {
                self.router.map("\(i)") { _, _, _, completed in completed() }
            }
        }
        
        testingQueue.async {
            for i in 1...1000 {
                self.router.map("\(i)") { _, _, _, completed in completed() }
            }
        }
        
        XCTAssertTrue(router.open("routingexample://route"))
    }
    
    func testShouldAllowTheSettingOfARouteHandlerCallbackQueue() {
        let expect = expectation(description: "Should allow setting of RouteHandler callback queue.")
        
        let callbackQueue = DispatchQueue(label: "Testing Call Back Queue", attributes: [])
        let key = DispatchSpecificKey<Void>()
        callbackQueue.setSpecific(key:key, value:())
        router.map("routingexample://route", queue: callbackQueue) { _, _, _, completed in
            if let _ = DispatchQueue.getSpecific(key: key) {
                expect.fulfill()
            }
            completed()
        }
        
        router.open("routingexample://route")
        waitForExpectations(timeout: 0.1, handler: nil)
    }
}

class RoutingProxyTests: XCTestCase {
    var router: Routing!
    var testingQueue: DispatchQueue!
    override func setUp() {
        super.setUp()
        router = Routing()
        testingQueue = DispatchQueue(label: "Testing Queue", attributes: DispatchQueue.Attributes.concurrent)
    }
    
    func testCanRedirectOpenedRoute() {
        let expect = expectation(description: "Proxy can redirect opened route.")
        
        var routeCalled = 0
        router.map("routingexample://route/one") { _, _, _, completed in
            routeCalled = 1
            expect.fulfill()
            completed()
        }
        
        router.map("routingexample://route/two") { _, _, _, completed in
            routeCalled = 2
            expect.fulfill()
            completed()
        }
        
        router.proxy("routingexample://route/one") { route, parameters, any, next in
            next(("routingexample://route/two", parameters, any))
        }
        
        router.open("routingexample://route/one")
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssert(routeCalled == 2)
    }
    
    func testCanMatchRouteWithWildCard() {
        let expect = expectation(description: "Proxy matches route with wildcard.")
        
        router.map("/route/one") { _, _, _, completed in completed() }
        
        var isProxied = false
        router.proxy("/route/*") { route, parameters, _, next -> Void in
            isProxied = true
            expect.fulfill()
            next(nil)
        }
        
        router.open("routingexample://route/one")
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertTrue(isProxied)
    }
    
    func testCanModifyURLArgumentsPassedToRouteHandler() {
        let expect = expectation(description: "Proxy modifies URL arguments passed to route.")
        
        var argument: String?
        router.map("routingexample://route/:argument") { _, parameters, _, completed in
            argument = parameters["argument"]
            expect.fulfill()
            completed()
        }
        
        router.proxy("routingexample://route/:argument") { route, parameters, any, next  in
            var parameters = parameters
            parameters["argument"] = "two"
            next((route, parameters, any))
        }
        
        router.open("routingexample://route/one")
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssert(argument == "two")
    }
    
    func testCanModifyQueryParametersPassedToRouteHandler() {
        let expect = expectation(description: "Proxy modifies query arameters passed to route.")
        
        var query: String?
        router.map("routingexample://route") { _, parameters, _, completed in
            query = parameters["query"]
            expect.fulfill()
            completed()
        }
        
        router.proxy("routingexample://route") { route, parameters, data, next in
            var parameters = parameters
            parameters["query"] = "bar"
            next((route, parameters, data))
        }
        
        router.open("routingexample://route?query=foo")
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssert(query == "bar")
    }
    
    func testCanModifyAnyPassedToRouteHandler() {
        let expect = expectation(description: "Proxy modifies any passed to route.")
        
        var passed: Any?
        router.map("routingexample://route") { _, _, any, completed in
            passed = any
            expect.fulfill()
            completed()
        }
        
        router.proxy("routingexample://route") { route, parameters, any, next in
            next((route, parameters, "anotherany"))
        }
        
        router.open("routingexample://route", passing: "any")
        waitForExpectations(timeout: 0.1, handler: nil)
        if let passed = passed as? String {
            XCTAssert(passed == "anotherany")
        } else {
            XCTFail()
        }
    }
    
    func testProxiesAreProcessedUntilAProxyCommitsChangesToNext() {
        let expect = expectation(description: "Proxies are called until a commit is made to Next().")
        
        router.map("routingexample://route") { _, parameters, _, completed in completed() }
        
        var results = [String]()
        router.proxy("routingexample://route") { route, parameters, _, next in
            results.append("three")
            next(nil)
        }
        
        router.proxy("routingexample://route") { route, parameters, _, next in
            results.append("two")
            expect.fulfill()
            next((route, Parameters(), nil))
        }
        
        router.proxy("routingexample://route") { route, parameters, _, next in
            results.append("one")
            next(nil)
        }
        
        router.open(URL(string: "routingexample://route")!)
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssert(results == ["one", "two"])
    }
    
    func testRouterIsAbleToOpenDespiteConcurrentReadWriteAccesses() {
        router.map("routingexample://route") { (_, _, _, completed) in completed() }
        
        testingQueue.async {
            for i in 1...1000 {
                self.router.proxy("\(i)") { route, parameters, any, next in next((route, parameters, any)) }
            }
        }
        
        testingQueue.async {
            for i in 1...1000 {
                self.router.proxy("\(i)") { route, parameters, any, next in next((route, parameters, any)) }
            }
        }
        
        XCTAssertTrue(router.open("routingexample://route"))
    }
    
    func testParametersAreMaintainedThroughProxyAndRouteHandlers() {
        let expect = expectation(description: "Parameters are maintained through proxy and route handlers.")
        
        var proxiedArgument, proxiedQuery: String?
        router.proxy("routingexample://route/:argument") { route, parameters, any, next in
            (proxiedArgument, proxiedQuery) = (parameters["argument"], parameters["query"])
            next((route, parameters, any))
        }
        
        var argument, query: String?
        router.map("routingexample://route/:argument") { _, parameters, _, completed in
            (argument, query) = (parameters["argument"], parameters["query"])
            expect.fulfill()
            completed()
        }
        
        router.open("routingexample://route/foo?query=bar")
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssert(proxiedArgument == "foo")
        XCTAssert(argument == "foo")
        XCTAssert(proxiedQuery == "bar")
        XCTAssert(query == "bar")
    }
    
    func testPassedAnyIsMaintainedThroughProxyAndRouteHandlers() {
        let expect = expectation(description: "Passed any is maintained through proxy and route handlers.")
        
        var proxiedPassed: Any?
        router.proxy("routingexample://route") { route, parameters, any, next in
            proxiedPassed = any
            next((route, parameters, any))
        }
        
        var passed: Any?
        router.map("routingexample://route") { _, _, any, completed in
            passed = any
            expect.fulfill()
            completed()
        }
        
        router.open("routingexample://route", passing: "any")
        waitForExpectations(timeout: 0.1, handler: nil)
        
        if let proxiedPassed = proxiedPassed as? String, let passed = passed as? String {
            XCTAssert(proxiedPassed == "any")
            XCTAssert(passed == "any")
        } else {
            XCTFail()
        }
    }
    
    func testShouldAllowTheSettingOfAProxyHandlerCallbackQueue() {
        let expect = expectation(description: "Should allow setting of ProxyHandler callback queue.")
        
        let callbackQueue = DispatchQueue(label: "Testing Call Back Queue", attributes: [])
        let key = DispatchSpecificKey<Void>()
        callbackQueue.setSpecific(key:key, value:())
        
        router.map("routingexample://route") { (_, _, _, completed) in completed() }
        
        router.proxy("routingexample://route", queue: callbackQueue) { route, parameters, any, next in
            if let _ = DispatchQueue.getSpecific(key: key) {
                expect.fulfill()
            }
            next((route, parameters, any))
        }
        
        router.open("routingexample://route")
        waitForExpectations(timeout: 0.1, handler: nil)
    }
}

class RoutingDisposeTests: XCTestCase {
    var router: Routing!
    var testingQueue: DispatchQueue!
    override func setUp() {
        super.setUp()
        router = Routing()
        testingQueue = DispatchQueue(label: "Testing Queue", attributes: DispatchQueue.Attributes.concurrent)
    }
    
    func testDisposingOfRouteUUID() {
        let uuid = router.map("routingexample://route") { _, _, _, completed in completed() }
        XCTAssertTrue(router.open("routingexample://route"))
        router.dispose(of: uuid)
        XCTAssertFalse(router.open("routingexample://route"))
    }
    
    func testDisposingOfProxyUUID() {
        let expect = expectation(description: "Proxy will be disposed and not redirect opened route.")
        
        var routeCalled = 0
        router.map("routingexample://route/one") { _, _, _, completed in
            routeCalled = 1
            expect.fulfill()
            completed()
        }
        
        router.map("routingexample://route/two") { _, _, _, completed in
            routeCalled = 2
            expect.fulfill()
            completed()
        }
        
        let uuid = router.proxy("routingexample://route/one") { route, parameters, any, next in
            next(("routingexample://route/two", parameters, any))
        }
        router.dispose(of: uuid)
        router.open("routingexample://route/one")
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssert(routeCalled == 1)
    }
    
    class testRouteOwner: RouteOwner {}
    
    func testDeallocatingOfRouterOwnerDisposesMappedRoute() {
        var owner: RouteOwner? = testRouteOwner()
        router.map("routingexample://route", owner: owner) { _, _, _, completed in completed() }
        XCTAssertTrue(router.open("routingexample://route"))
        owner = nil
        XCTAssertFalse(router.open("routingexample://route"))
    }
    
    func testDeallocatingOfRouterOwnerDisposesProxiedRoute() {
        let expect = expectation(description: "Proxy will be disposed and not redirect opened route.")
        
        var routeCalled = 0
        router.map("routingexample://route/one") { _, _, _, completed in
            routeCalled = 1
            expect.fulfill()
            completed()
        }
        
        router.map("routingexample://route/two") { _, _, _, completed in
            routeCalled = 2
            expect.fulfill()
            completed()
        }
        
        var owner: RouteOwner? = testRouteOwner()
        router.proxy("routingexample://route/one", owner: owner) { route, parameters, any, next in
            next(("routingexample://route/two", parameters, any))
        }
        owner = nil
        router.open("routingexample://route/one")
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssert(routeCalled == 1)
    }
}

class RoutingTagTests: XCTestCase {
    var router: Routing!
    var testingQueue: DispatchQueue!
    override func setUp() {
        super.setUp()
        router = Routing()
        testingQueue = DispatchQueue(label: "Testing Queue", attributes: DispatchQueue.Attributes.concurrent)
    }
    
    func testSubscriptingRouterOpen() {
        let expect = expectation(description: "When subscripted first #mapped RouteHandler is called.")
        
        var routeCalled = 0
        router.map("routingexample://route", tags: ["First"]) { _, _, _, completed in
            routeCalled = 1
            expect.fulfill()
            completed()
        }
        
        router.map("routingexample://route") { _, _, _, completed in
            routeCalled = 2
            expect.fulfill()
            completed()
        }
        
        router["First"].open("routingexample://route")
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssert(routeCalled == 1)

    }
    
    func testSubscriptingRouterTargetQueue() {
        let expect = expectation(description: "When subscripted order is still preserved due to target queue.")
        
        var results = [String]()
        router.map("routingexample://route", tags: ["First"]) { _, _, _, completed in
            results.append("one")
            completed()
        }
        
        router.map("routingexample://route", tags: ["Second"]) { _, _, _, completed in
            expect.fulfill()
            results.append("two")
            completed()
        }
        
        router["First"].open("routingexample://route")
        router["Second"].open("routingexample://route")
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssert(results == ["one", "two"])
    }
}

class RoutingPerformanceTests: XCTestCase {
    var router: Routing!
    var testingQueue: DispatchQueue!
    override func setUp() {
        super.setUp()
        router = Routing()
        testingQueue = DispatchQueue(label: "Testing Queue", attributes: DispatchQueue.Attributes.concurrent)
    }
    
    func testPerfomance() {
        // NOTE: 1000 takes ~8 seconds seems exponential
        let num = 100
        for i in 1...num {
            print("\(i)")
            router.map("\(i)") { _, _, _, completed in completed() }
        }
        
        measure {
            let expect = self.expectation(description: "Waiting on num + 1.")
            let uuid = self.router.map("\(num + 1)") { _, _, _, completed in
                expect.fulfill()
                completed()
            }
            
            for i in 1...(num + 1) {
                self.router.open("\(i)")
            }
            self.waitForExpectations(timeout: 5, handler: nil)
            self.router.dispose(of: uuid)
        }
    }
}
