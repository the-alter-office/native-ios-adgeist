import Foundation

public class CdpClient {
    private let deviceIdentifier: DeviceIdentifier
    private let bearerToken: String
    private let cdpDomain = "rl2ptnqw5f.execute-api.ap-south-1.amazonaws.com"
    
    init(deviceIdentifier: DeviceIdentifier, bearerToken: String) {
        self.deviceIdentifier = deviceIdentifier
        self.bearerToken = bearerToken
    }
    
    public func sendEventToCdp(_ event: Event) {
        deviceIdentifier.getDeviceIdentifier { [weak self] deviceId in
            guard let self = self else { return }
            
            let userIP = self.getLocalIPAddress() ?? "unknown"
            
            // Structure the traits
            var traits: [String: Any?] = [
                "consent_given": true,
                "source": "mobile",
                "timestamp": Date().toISOString(),
                "apple_ad_id": deviceId
            ]
            
            // Clean event properties and merge userDetails into traits
            var cleanedEventProperties = event.eventProperties ?? [:]
            if let userDetails = cleanedEventProperties.removeValue(forKey: "userDetails") as? [String: Any] {
                traits.merge(userDetails) { (_, new) in new }
            }
            
            // Structure the request body
            let requestBody: [String: Any] = [
                "event_type": event.eventType,
                "traits": traits,
                "event_properties": cleanedEventProperties
            ]
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
                print("CdpClient: Failed to serialize request body")
                return
            }
            
            let urlString = "http://\(self.cdpDomain)/ingest"
            guard let url = URL(string: urlString) else {
                print("CdpClient: Invalid URL")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = jsonData
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(self.bearerToken)", forHTTPHeaderField: "Authorization")
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("CdpClient: Error sending event: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("CdpClient: Event sent successfully")
                    } else {
                        print("CdpClient: Failed to send event, status: \(httpResponse.statusCode)")
                    }
                }
            }
            
            task.resume()
        }
    }

    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                let interface = ptr?.pointee
                let addrFamily = interface?.ifa_addr.pointee.sa_family
                
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    let name = String(cString: (interface?.ifa_name)!)
                    if name == "en0" || name == "pdp_ip0" || name == "pdp_ip1" || name == "pdp_ip2" || name == "pdp_ip3" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface?.ifa_addr, socklen_t((interface?.ifa_addr.pointee.sa_len)!), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        
        return address
    }
}