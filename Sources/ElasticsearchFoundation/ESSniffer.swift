import Foundation

/// Uses a given transport to snif elasticsearch hosts
class ESSniffer {
    internal var transport : ESTransport
    
    init(transport: ESTransport) {
        self.transport = transport
    }
    
    /// Returns an array of URLComponents (hosts) queried from the transport
    func hosts() -> [URLComponents] {
        let response = transport.request(method: .GET, path: "_nodes/http")
        switch response {
        case .ok(_, let body):
            guard let json = body?.toDict() else { return [] }
            guard let nodes = json["nodes"] as? [String: Any] else { return [] }
            
            var result : [URLComponents] = []
            for (_, data) in nodes  {
                if let nodeData = data as? [String: Any],
                    let urlString = nodeData["\(transport.transportProtocol)_address"] as? String,
                    let url = URLComponents(string: urlString) {
                            result.append(url)
                    }
            }
            return result
        default: break
        }
        return []
    }
}
