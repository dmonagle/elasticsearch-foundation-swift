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
        try transport.addHost(string: "http://localhost:9200")
        
        let response = transport.request(method: .GET)
        switch response {
        case .error(let error):
            debugPrint("Error!")
            switch (error) {
            case .invalidJsonResponse(let data):
                debugPrint(String(data: data, encoding: String.Encoding.utf8) ?? "")

            default:
                debugPrint(error)
            }
        case .ok(let response, let body):
            debugPrint("Success!")
            debugPrint(response)
            debugPrint(body ?? "")
        }
        
        let sniffer = ESSniffer(transport: transport)
        debugPrint(sniffer.hosts())
    }

    func testRequestWithGetBody() throws {
        var settings = ESTransportSettings()
        settings.maxRetries = 0
        let transport = ESTransport(settings: settings)
        try transport.addHost(string: "http://localhost:9200")
        let response = transport.request(method: .GET, path: "_count", requestBody: "{ \"query\": { \"match_all\": {} } }")
        switch response {
        case .error(let error):
            debugPrint("Error!")
            debugPrint(error)
        case .ok(let response, let body):
            debugPrint("Success!")
            debugPrint(response)
            debugPrint(body ?? "")
        }
    }

}
