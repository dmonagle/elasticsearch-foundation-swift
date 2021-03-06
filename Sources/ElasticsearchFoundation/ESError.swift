//
//  ErrorHandling.swift
//  Elasticsearch
//
//  Created by David Monagle on 22/11/16.
//
//

import Foundation

public enum ESError : Error {
    case invalidConnection(ESConnection)
    case noConnectionsAvailable
    case requestError(URLResponse?, Error, Data?)
    case invalidHttpResponse(URLResponse?)
    case invalidJsonResponse(Data)
    case missingRequiredParameter(String)
    case emptyRequiredParameter(String)
    case apiError(HTTPURLResponse, ESResponseBody)
    case unknown
}

extension ESError : CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidConnection(let connection):
            return "Attempted to add a connection to a ConnectionPool but it has no valid URL: \(connection)"
        case .noConnectionsAvailable:
            return "No connections available"
        case .requestError(let response, let error, let data):
            return "Request Error: \(error)\n\(String(describing: response))\n\(String(describing: data))"
        case .invalidHttpResponse(let response):
            return "Did not get a valid HTTP response: \n\(String(describing: response))"
        case .invalidJsonResponse(let data):
            return "Invalid JSON response: \n\(data)"
        case .missingRequiredParameter(let name):
            return "Missing a required parameter: \(name)"
        case .emptyRequiredParameter(let name):
            return "Required parameter is present but empty: \(name)"
        case .apiError(let response, let body):
            return "Elasticsearch API returned an error: \(response.statusCode)\n\(body)"
        default:
            return "Elasticsearch Error"
        }
    }
}
