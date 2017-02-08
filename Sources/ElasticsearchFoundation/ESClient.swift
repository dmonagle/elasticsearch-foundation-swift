//
//  ESClient.swift
//  ElasticsearchFoundation
//
//  Created by David Monagle on 25/11/16.
//
//

import Foundation

// Elasticsearch Client Class
public class ESClientFoundation {
    internal var _transport: ESTransport
    
    public init(settings: ESTransportSettings = ESTransportSettings()) {
        _transport = ESTransport(settings: settings)
    }
    
    public func addHost(_ host: URLComponents) throws {
        try _transport.addHost(url: host)
    }
    
    public func request(method: RequestMethod = .GET, path: String = "", parameters: ESParams = [:], requestBody: String? = nil) -> ESResponse {
        return _transport.request(method: method, path: path, parameters: parameters, requestBody: requestBody)
    }
}
