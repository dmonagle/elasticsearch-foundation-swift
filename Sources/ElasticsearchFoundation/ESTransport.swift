//
//  ESTransport.swift
//  ElasticsearchFoundation
//
//  Created by David Monagle on 14/09/2016.
//
//

import Foundation

public enum RequestMethod : String {
    case HEAD
    case GET
    case POST
    case PUT
    case DELETE
}

public enum ESResponse {
    case success(Dictionary<String, Any>)
    case failure(ESError)
}

public struct ESTransportSettings {
    var reloadOnFailure : Bool = true
    var reloadAfter : Int = 10000 /// Requests
    var resurrectAfter : Int = 60 /// Seconds
    var maxRetries = 3 /// Requests
    var baseConnectionTimeout : TimeInterval = 60 /// The base time a connection stays dead for
    var requestTimeout : TimeInterval = 15 /// Timeout for each HTTPRequest
}

open class ESTransport {
    public var transportProtocol : String = "http"
    internal var _hosts : [URLComponents] = []
    internal var _connectionPool : ConnectionPool = ConnectionPool()
    internal var _connectionCounter : Int = 0
    internal var _settings : ESTransportSettings
    
    public init(settings: ESTransportSettings? = nil) {
        if let s = settings {
            _settings = s
        }
        else {
            _settings = ESTransportSettings()
        }
        _connectionPool = ConnectionPool()
    }
    
    public func addConnection(_ connection: ESConnection) throws {
        try _connectionPool.add(connection: connection)
    }
    
    public func addHost(url: URLComponents) throws {
        try addConnection(ESConnection(url: url, baseTimeout: _settings.baseConnectionTimeout))
    }
    
    public func addHost(string: String) throws {
        if let url = URLComponents(string: string) {
            try addHost(url: url)
        }
    }
    
    
    internal func buildConnections() {
        _connectionPool = ConnectionPool()
        _connectionCounter = 0
        for host in _hosts {
            try? addHost(url: host)
        }
    }
    
    /// Returns a connection from the connection pool by delegating to Collection.
    ///
    /// Resurrects dead connection if the `resurrectAfter` timeout has passed.
    /// Increments the counter and performs connection reloading if the `reload_connections` option is set.
    ///
    /// @return [Connections::ESConnection]
    /// @see    Connections::Collection///get_connection
    ///
    public func getConnection() -> ESConnection? {
        if (_connectionPool.length == 0) { buildConnections() }
        // Reload connections if we've hit the reloadAfter
        if (_settings.reloadAfter != 0 && (_connectionCounter >= _settings.reloadAfter)) {
            sniffConnections()
        }
        
        if let connection = _connectionPool.nextConnection() {
            _connectionCounter += 1
            
            
            return connection;
        }
        
        return nil
    }
    
    /// Reloads and replaces the connection collection based on cluster information.
    public func sniffConnections() {
        let sniffer = ESSniffer(transport: self)
        let hosts = sniffer.hosts()
        if (hosts.count > 0) { _hosts = hosts }
        buildConnections();
    }
    
    /// Tries to "resurrect" all eligible dead connections.
    ///
    /// @see Connections::ESConnection///resurrect!
    ///
    internal func resurrectDeadConnections() {
        for connection in _connectionPool.deadConnections {
            connection.resurrect();
        }
    }
    
    public func request(connection: ESConnection? = nil, method: RequestMethod, path: String = "", parameters: ESParams = [:], requestBody: String? = nil, callback: @escaping (ESResponse) -> ()) {
        if let connection = connection ?? getConnection() {
            
            if let url = connection.host.url {
                let requestURL = url.appendingPathComponent(path)
                var request = URLRequest(url: requestURL)
                request.httpMethod = method.rawValue
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.timeoutInterval = _settings.requestTimeout
                if let body = requestBody {
                    request.httpBody = body.data(using: .utf8)
                    // As there is an issue sending a body with a GET, we take the advice of Elasticsearch and change the request to a .POST
                    //
                    // From https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-body.html
                    // Both HTTP GET and HTTP POST can be used to execute search with body. Since not all clients support GET with body, POST is allowed as well.
                    if (method == .GET) {
                        request.httpMethod = "POST"
                    }
                }
                
                let task = URLSession.shared.dataTask(with: request) {
                    (data, response, error) in
                    if let error = error {
                        callback(.failure(.requestError(error, data)))
                    }
                    else {
                        if let httpResponse = response as? HTTPURLResponse {
                            if let data = data {
                                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any] {
                                    if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                                        callback(.success(json))
                                    }
                                    else {
                                        callback(.failure(.apiError(httpResponse, json)))
                                    }
                                }
                                else {
                                    callback(.failure(.invalidJsonResponse(data)))
                                }
                            }
                            else {
                                callback(.success([:]))
                            }
                        }
                        else {
                            callback(.failure(.invalidHttpResponse(response)))
                        }
                    }
                }
                task.resume()
            }
            else {
                callback(.failure(ESError.invalidConnection(connection)))
            }
        }
        else {
            callback(.failure(ESError.noConnectionsAvailable))
        }
    }
    
    public func request(connection: ESConnection? = nil, method: RequestMethod, path: String = "", parameters: ESParams = [:], requestBody: String = "") -> ESResponse {
        var result : ESResponse?
        let semaphore = DispatchSemaphore(value: 0)

        var retries = 0
        
        repeat {
            request(connection: connection, method: method, path: path, parameters: parameters, requestBody: requestBody) {
                response in
                switch response {
                case .success:
                    result = response
                case .failure(let error):
                    switch error {
                        
                    case .apiError(_, _):
                        // Do not retry for these error types
                        result = response // No more retrying
                    default:
                        // Retry
                        if (retries == self._settings.maxRetries) {
                            debugPrint("Max retries reached")
                            result = response // No more retrying
                        }
                        else {
                            retries += 1
                            debugPrint("Retry \(retries)")
                        }
                    }
                }
                semaphore.signal()
            }
            semaphore.wait()
        } while (result == nil)

        return result!
    }
}

