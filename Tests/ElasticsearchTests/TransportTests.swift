//
//  ESTransport.swift
//  ElasticsearchFoundation
//
//  Created by David Monagle on 14/09/2016.
//
//

import XCTest
@testable import ElasticsearchFoundation

class TransportTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testRequest() throws {
        let transport = ESTransport()
        try transport.addConnection(ESConnection(url: URLComponents(string: "http://localhost:9200")!))
        
        let response = transport.request(method: .GET)
        switch response {
        case .failure(let error):
            debugPrint("Error!")
            debugPrint(error)
        case .success(let response):
            debugPrint("Success!")
            debugPrint(response)
        }
        
        let sniffer = ESSniffer(transport: transport)
        debugPrint(sniffer.hosts())
    }
}
