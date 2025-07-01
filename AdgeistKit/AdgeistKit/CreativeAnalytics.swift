//
//  CreativeAnalytics.swift
//  AdgeistKit
//
//  Created by kishore on 02/05/25.
//

import Foundation

public class CreativeAnalytics {
    private let deviceIdentifier: DeviceIdentifier
    
    init(deviceIdentifier: DeviceIdentifier) {
        self.deviceIdentifier = deviceIdentifier
    }
    
    public func sendTrackingData(
        campaignId: String,
        adSpaceId: String,
        publisherId: String,
        eventType: String,
        origin: String,
        apiKey: String,
        bidId: String,
        isTestEnvironment: Bool = true,
        completion: @escaping (String?) -> Void
    ) {
        deviceIdentifier.getDeviceIdentifier { deviceId in
            print("Successfully fetched Device ID: \(deviceId)")
            
            let userIP = self.getLocalIPAddress() ?? "unknown"
            let envFlag = isTestEnvironment ? "1" : "0"
            let urlString = "https://bg-services-api.adgeist.ai/api/analytics/track?adSpaceId=\(adSpaceId)&companyId=\(publisherId)&test=\(envFlag)"
            
            guard let url = URL(string: urlString) else {
                completion(nil)
                return
            }
            
            let requestBodyJson: [String: Any] = [
                "eventType": eventType,
                "winningBidId": bidId,
                "campaignId": campaignId
            ]
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBodyJson) else {
                completion(nil)
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = jsonData
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(origin, forHTTPHeaderField: "Origin")
            request.addValue(deviceId, forHTTPHeaderField: "x-user-id")
            request.addValue("mobile_app", forHTTPHeaderField: "x-platform")
            request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.addValue(userIP, forHTTPHeaderField: "x-forwarded-for")
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Failed to send tracking data: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(nil)
                    return
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    let errorBody = data != nil ? String(data: data!, encoding: .utf8) ?? "No error message" : "No error message"
                    print("Request failed with code: \(httpResponse.statusCode), message: \(errorBody)")
                    completion(nil)
                    return
                }
                
                if let data = data, let jsonString = String(data: data, encoding: .utf8) {
                    print("Tracking data sent successfully: \(jsonString)")
                    completion(jsonString)
                } else {
                    completion(nil)
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
