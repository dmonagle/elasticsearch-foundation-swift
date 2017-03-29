import Foundation

/**
 * Wraps the connection information and logic.
 *
 * The ESConnection instance wraps the host information (hostname, port, attributes, etc),
 * as well as the "session" (a transport client object, such as a {elasticsearch.transport.http.vibe} instance).
 *
 * It provides methods to construct and properly encode the URLs and paths for passing them
 * to the transport client object.
 *
 * It provides methods to handle connection lifecycle (dead, alive, healthy).
 */
open class ESConnection {
    internal var _host : URLComponents
    internal var _failures = 0
    internal var deadSince : Date?
    internal var _baseTimeout : TimeInterval
    
    /// The host of this connection
    open var host : URLComponents {
        get {
            return _host
        }
    }
    
    public init(url: URLComponents, baseTimeout: TimeInterval = 60) {
        _host = url
        _baseTimeout = baseTimeout
    }
    
    convenience init?(string urlString: String, baseTimeout: TimeInterval = 60) {
        guard let url = URLComponents(string: urlString) else { return nil }
        self.init(url: url)
    }
    
    /// Returns true if the host URL is valid
    open var isValid : Bool {
        if (host.url == nil) { return false }
        return true
    }
    
    /// Returns true if the connection has been marked as dead
    open var isDead : Bool {
        return (deadSince != nil) ? true : false
    }
    
    /// Returns true if the connection has not been marked as dead
    open var isAlive : Bool { return !isDead }
    
    /// Returns true if the connection is dead longer than the resurrection timeout
    open var isResurrectable : Bool {
        let currentTime = Date()
        
        if let deadSince = deadSince {
            return currentTime > deadSince + currentTimeout;
        }
        return false
    }
    
    /// Returns what the current resurrection timeout should be
    open var currentTimeout : TimeInterval {
        return _baseTimeout * pow(2.0, Double(_failures - 1))
    }
    
    /**
     * Marks this connection as dead, incrementing the `failures` counter and
     * storing the current time as `dead_since`.
     */
    internal func makeDead() {
        deadSince = Date()
        _failures += 1
    }
    
    /// Marks this connection as alive, ie. it is eligible to be returned from the pool by the selector.
    internal func makeAlive() {
        deadSince = nil
    }
    
    /// Marks this connection as healthy, ie. a request has been successfully performed with it.
    internal func makeHealthy() {
        makeAlive()
        _failures = 0
    }
    
    /// Resurrects the connection if it is eligiable
    internal func resurrect(force: Bool = false) {
        if (isResurrectable || force) { makeAlive() }
    }
}

extension ESConnection : CustomStringConvertible {
    open var description: String {
        var description = "<ESConnection host: \(host) "
        if let deadSince = deadSince {
            description += "dead since \(deadSince)"
        }
        else {
            description += "alive"
        }
        description += ">"
        return description
    }
}

extension ESConnection : Hashable, Equatable {
    // Satisfy the Hashable Protocol
    open var hashValue: Int {
        return (_host.string?.hashValue) ?? 0
    }
    
    // Satisfy the Equatable Protocol
    open static func == (lhs: ESConnection, rhs: ESConnection) -> Bool {
        return lhs._host == rhs.host
    }
}

// MARK: - ESConnection Pool

/// Manages a pool of connections
public class ConnectionPool {
    var connections : [ESConnection] { get { return _connections } }
    var selector : ConnectionSelector = RoundRobinSelector()
    var length : UInt32 { return UInt32(aliveConnections.count) }
    var aliveConnections : [ESConnection] { return connections.filter({ $0.isAlive }) }
    var deadConnections : [ESConnection] { return connections.filter({ !$0.isAlive }).sorted(by: { $0.deadSince! < $1.deadSince! })}
    
    private var _connections : [ESConnection] = []
    
    /**
     * Returns a connection.
     *
     * If there are no alive connections, resurrects a connection with least failures.
     * Delegates to selector's `*select` method to get the connection.
     *
     */
    public func nextConnection() -> ESConnection? {
        if (connections.isEmpty) { return nil }
        resurrectConnections()
        
        if (aliveConnections.count == 0) {
            deadConnections[0].makeAlive()
        }
        
        return aliveConnections[Int(selector.select(fromPool: self))]
    }
    
    /// Resurrects all eligable connections
    internal func resurrectConnections() {
        for connection in deadConnections {
            if (connection.isResurrectable) {
                connection.makeAlive()
            }
            else {
                // As these are sorted by deadSince, as soon as we hit one that's not resurrectable we can break
                break
            }
        }
    }
    
    /// Adds a connection to the pool.
    public func add(connection: ESConnection) throws {
        if (connection.isValid) {
            _connections.append(connection)
        }
        else {
            throw ESError.invalidConnection(connection)
        }
    }
}

// MARK: - Selectors

protocol ConnectionSelector {
    mutating func select(fromPool pool: ConnectionPool) -> UInt32
}

struct RoundRobinSelector : ConnectionSelector {
    private var _current : UInt32 = 0
    
    mutating func select(fromPool pool: ConnectionPool) -> UInt32 {
        let result : UInt32
        if (_current >= pool.length) {
            _current = 0
            result = 0
        }
        else {
            result = _current
            _current += 1
        }
        
        return result
    }
}



