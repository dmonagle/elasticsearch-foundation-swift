//
//  ConnectionTest.swift
//  ElasticsearchFoundation
//
//  Created by David Monagle on 14/09/2016.
//
//

import XCTest
@testable import Elasticsearch

class ConnectionTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDeadTracking() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let host = URLComponents(string: "http://localhost:9200")
        let connection = ESConnection(url: host!)
        XCTAssert(connection.isAlive)
        connection.makeDead()
        XCTAssert(connection.isDead)
        XCTAssert(connection._failures == 1)
        XCTAssertEqual(connection._failures, 1)
        XCTAssert(!connection.isResurrectable)
        connection.resurrect() // This should not be able to make the connection alive as it hasn't been dead long enough
        XCTAssert(connection.isDead)
        connection.deadSince = Date() - 120 // Fake deadSince to be 2 minutes ago
        XCTAssert(connection.isResurrectable)
        connection.resurrect() // This should work now
        XCTAssert(connection.isAlive)
        XCTAssertEqual(connection._failures, 1) // Failures is stil 1 because the connection has not been deemed healthy
        connection.makeHealthy()
        XCTAssertEqual(connection._failures, 0)
        debugPrint(connection)
    }
}
