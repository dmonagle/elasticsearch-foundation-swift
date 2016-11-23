//
//  Parameter.swift
//  Elasticsearch
//
//  Created by David Monagle on 22/11/16.
//
//  Extensions to the Dictionary type to allow manipulation of Elasticsearch parameters

import Foundation


/// Common ES parameters
/// parameters like index, type and id are not included  as they are normally passed in the path of the request
let ES_COMMON_PARAMETERS = [
    "ignore",
    "body",
    "node_id",
    "name",
    "field"
]

/// Common ES parameters used in queries
let ES_COMMON_QUERY_PARAMETERS = [
    "format",
    "pretty",
    "human"
]

/// ESParams
public typealias ESParams = Dictionary<String, String>

extension Dictionary {
    /// Returns the value of the specified key or the default value given
    public func value(of key: Key, or defaultValue: Value) -> Value {
        return self[key] ?? defaultValue
    }
    
    /// Returns a dictionary that only contains the keys allowed
    public func only(_ allowed: [Key]) -> Dictionary<Key, Value> {
        let filtered = self.filter({allowed.contains($0.key)})
        
        var dict : Dictionary<Key, Value> = [:]
        for (key, value) in filtered {
            dict[key] = value
        }
        return dict
    }
    
    
    /// Returns a dictionary that only contains the keys allowed
    public func only(_ allowed: Key ...) -> Dictionary<Key, Value> {
        return only(allowed)
    }

    /// Throws an ESError if the given name isn't set, otherwise returns the value
    public func elasticSearchEnforceParameter(_ name: String) throws -> Value {
        let key = name as! Key
        if let value = self[key] as? String {
            if (value.isEmpty) { throw ESError.emptyRequiredParameter(name) }
            return self[key]!
        }
        else {
            throw ESError.missingRequiredParameter(name)
        }
    }

    /// Sets a key to the given value if it's not already set
    public mutating func setDefault(for key: Key, to value: Value) {
        if (self[key] == nil) { self[key] = value }
    }
    
    /// Returns a new list of params which will only included common parameters plus those `allowed` passed in parameters
    public func elasticsearchExtractParameters(_ allowed: [Key]) -> Dictionary<Key, Value> {
        var allKeys : [Key] = allowed
        allKeys += (ES_COMMON_PARAMETERS.map { $0 as! Key })
        allKeys += (ES_COMMON_QUERY_PARAMETERS.map { $0 as! Key })
        return only(allKeys)
    }

    public func elasticsearchExtractParameters(_ allowed: Key ...) -> Dictionary<Key, Value> {
        return elasticsearchExtractParameters(allowed)
    }
}


/// Escapes the given string for use with ES API
extension String {
    func elasticsearchEscape() -> String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}

/// Takes an array of strings representing a path and returns a clean path string
public func esPathify(_ path: String ...) -> String {
    var stripCharacters = CharacterSet.whitespacesAndNewlines
    stripCharacters.insert("/")
    return
        path.map { $0.trimmingCharacters(in: stripCharacters) }
            .filter { !$0.isEmpty }
            .joined(separator: "/")
}

/// Creates a comma separated list from the given arguements
public func esListify(_ list: String ...) -> String {
    return
        list.filter { !$0.isEmpty }
            .map { $0.elasticsearchEscape() }
            .joined(separator: ",")
}
