# ElasticsearchFoundation for Swift 3.0

Implements the transport side of Elasticsearch using only Foundation as a dependency. Based loosly on the office client designs.

The client supports both asynchronous requests and also synchronous requests with retry. Asynchronous requests do not retry at this point.

Error handling is done in an elegant Swift like fashion.

This class can be used as a base for a client which can then add better API convenience functions as well as using other frameworks for the JSON data. 

## Create a new transport

You can create a new transport by calling the default initializer 
```swift
        let transport = ESTransport()
```

You can add a host by passing either URLComponents or by passing a string
```swift
        try transport.addConnection(ESConnection(url: URLComponents(string: "http://localhost:9200")!))
```

## Using the response

```swift
        let response = transport.request(method: .GET)
        switch response {
        case .failure(let error):
            debugPrint("Error!")
            debugPrint(error)    // This will be an ESError
        case .success(let response):
            debugPrint("Success!")
            debugPrint(response) // This will be a Dictionary
        }
```


## Client Example 

Below is the basic idea of how to implement a client class based on this transport 

```swift
// Elasticsearch Client Class
public class ESClient {
    internal var _transport: Transport
    
    public init(settings: ESTransportSettings = ESTransportSettings()) {
        _transport = Transport(settings: settings)
    }
    
    public func addHost(_ host: URLComponents) throws {
        try _transport.addHost(url: host)
    }
    
    public func request(method: RequestMethod = .GET, path: String = "", parameters: ESParams = [:], requestBody: String = "") -> ESResponse {
        return _transport.request(method: method, path: path, parameters: parameters, requestBody: requestBody)
    }
}

public extension ESClient {
    func get(parameters: ESParams = [:]) throws -> ESResponse {
        let index = try parameters.elasticSearchEnforceParameter(name: "index")
        let id = try parameters.elasticSearchEnforceParameter(name: "id")
        let type = parameters.value(of: "type", or: "_all")
        
        var requestParams = parameters.elasticsearchExtractParameters(
            "fields", "parent", "preference", "realtime", "refresh", "routing", "version", "version_type",
            "_source", "_source_include", "_source_exclude", "_source_transform"
        )
        
        let path = esPathify(index, type, id)
        return request(path: path, parameters: requestParams)
    }
    
    func get(index: String, type: String? = nil, id: String) throws -> ESResponse  {
        var parameters = ["index": index, "id": id]
        if let type = type { 
            parameters["type"] = type 
        }
        return try get(parameters: parameters)
    }
}
```