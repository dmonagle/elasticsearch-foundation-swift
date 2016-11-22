//
//  Parameters.swift
//  ElasticsearchFoundation
//
//  Created by David Monagle on 14/09/2016.
//
//

import XCTest
@testable import Elasticsearch

class ParametersTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDefaultValue() {
        let params : ESParams = ["one": "1", "two": "2"]
        
        XCTAssertEqual(params.value(of: "one", or: "5"), "1")
        XCTAssertEqual(params.value(of: "three", or: "3"), "3")
    }
    
    func testPathify() {
        XCTAssertEqual(esPathify("one/", "/", "two ", "\n", "//three"), "one/two/three")
    }

    func testListify() {
        XCTAssertEqual(esListify("A", "B"), "A,B")
        XCTAssertEqual(esListify("one", "two^three"), "one,two%5Ethree")
    }

    func testFilter() {
        let dict = ["one": "1", "two": "2", "three": "3"]
        let filteredTwo = dict.only("two")
        XCTAssertEqual(filteredTwo.count, 1)
        XCTAssertEqual(filteredTwo["two"], "2")
    }

    func testEnforceParameter() throws {
        let dict = ["one": "1", "two": "2", "three": "3"]
        try _ = dict.elasticSearchEnforceParameter("one")
        XCTAssertThrowsError(try _ = dict.elasticSearchEnforceParameter("five"), "five should not exist")
    }
    
    func test() {
        let dict = [
            "pretty": "true",
            "field": "name",
            "junk": "remove",
            "mine": "special"
        ]
        
        let e1 = dict.elasticsearchExtractParameters()
        XCTAssertEqual(e1["junk"], nil)
        XCTAssertEqual(e1["mine"], nil)
        XCTAssertEqual(e1["pretty"], "true")
        XCTAssertEqual(e1["field"], "name")

        let e2 = dict.elasticsearchExtractParameters("mine")
        XCTAssertEqual(e2["junk"], nil)
        XCTAssertEqual(e2["mine"], "special")
        XCTAssertEqual(e2["pretty"], "true")
        XCTAssertEqual(e2["field"], "name")
    }
}
