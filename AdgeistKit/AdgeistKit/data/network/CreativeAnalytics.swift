import Foundation

public class CreativeAnalytics {
    private let deviceIdentifier: DeviceIdentifier
    private let domain: String
    
    // Event types that align with web SDK EVENT_TYPES
    public static let IMPRESSION = "IMPRESSION"
    public static let VIEW = "VIEW"
    public static let TOTAL_VIEW = "TOTAL_VIEW"
    public static let CLICK = "CLICK"
    public static let VIDEO_PLAYBACK = "VIDEO_PLAYBACK"
    public static let VIDEO_QUARTILE = "VIDEO_QUARTILE"
    
    private static let TAG = "CreativeAnalytics"
    
    init(deviceIdentifier: DeviceIdentifier, domain: String) {
        self.deviceIdentifier = deviceIdentifier
        self.domain = domain
    }

    // Core method to send tracking data to backend
    public func sendTrackingData(
        campaignId: String,
        adSpaceId: String,
        publisherId: String,
        eventType: String,
        origin: String,
        apiKey: String,
        bidId: String,
        bidMeta: String,
        buyType: String,
        isTestEnvironment: Bool = true,
        additionalProperties: [String: Any] = [:],
        completion: @escaping (String?) -> Void
    ) {
        deviceIdentifier.getDeviceIdentifier { [weak self] deviceId in
            guard let self = self else {
                completion(nil)
                return
            }
            
            print("Successfully fetched Device ID: \(deviceId)")
            
            let userIP = self.getLocalIPAddress() ?? "unknown"
            let envFlag = isTestEnvironment ? "1" : "0"
            
            let urlString: String
            if buyType == "FIXED" {
                urlString = "https://\(self.domain)/v2/ssp/impression"
            } else {
                urlString = "https://\(self.domain)/api/analytics/track?adSpaceId=\(adSpaceId)&companyId=\(publisherId)&test=\(envFlag)"
            }

            guard let url = URL(string: urlString) else {
                print("\(Self.TAG): Invalid URL: \(urlString)")
                completion(nil)
                return
            }
            
            // Build request body JSON based on buyType
            var requestBodyJson: [String: Any]
            
            if buyType == "FIXED" {
                requestBodyJson = [
                    "type": eventType,
                    "metaData": bidMeta
                ]
                // Merge additional properties
                for (key, value) in additionalProperties {
                    requestBodyJson[key] = value
                }
            } else {
                requestBodyJson = [
                    "eventType": eventType,
                    "winningBidId": bidId,
                    "campaignId": campaignId
                ]
                // Merge additional properties
                for (key, value) in additionalProperties {
                    requestBodyJson[key] = value
                }
            }
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBodyJson) else {
                print("\(Self.TAG): Failed to serialize JSON")
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
                    print("\(Self.TAG): Failed to send tracking data: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("\(Self.TAG): Invalid response type")
                    completion(nil)
                    return
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    let errorBody = data != nil ? String(data: data!, encoding: .utf8) ?? "No error message" : "No error message"
                    print("\(Self.TAG): Request failed with code: \(httpResponse.statusCode), message: \(errorBody)")
                    completion(nil)
                    return
                }
                
                if let data = data, let jsonString = String(data: data, encoding: .utf8) {
                    print("\(Self.TAG): Tracking data sent successfully: \(jsonString)")
                    completion(jsonString)
                } else {
                    completion(nil)
                }
            }
            
            task.resume()
        }
    }
    
    // V2 API - Send tracking data using AnalyticsRequest
    public func sendTrackingDataV2(analyticsRequest: AnalyticsRequest) {
        let url = "https://\(domain)/v2/ssp/impression"
        
        guard let urlObj = URL(string: url) else {
            print("\(Self.TAG): Invalid URL: \(url)")
            return
        }
        
        let requestPayload = analyticsRequest.toJson()
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestPayload) else {
            print("\(Self.TAG): Failed to serialize JSON")
            return
        }
        
        print("\(Self.TAG): Sending tracking data: \(String(data: jsonData, encoding: .utf8) ?? "")")
        
        var request = URLRequest(url: urlObj)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("\(Self.TAG): Failed to send tracking data: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("\(Self.TAG): Invalid response type")
                return
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                let errorBody = data != nil ? String(data: data!, encoding: .utf8) ?? "No error message" : "No error message"
                print("\(Self.TAG): Request failed with code: \(httpResponse.statusCode), message: \(errorBody)")
                return
            }
            
            print("\(Self.TAG): Tracking data sent successfully")
        }
        
        task.resume()
    }
    
    // Track impression
    public func trackImpression(
        campaignId: String,
        adSpaceId: String,
        publisherId: String,
        apiKey: String,
        bidId: String,
        bidMeta: String,
        buyType: String,
        isTestEnvironment: Bool,
        renderTime: Float
    ) {
        let properties: [String: Any] = [
            "renderTime": renderTime
        ]
        
        sendTrackingData(
            campaignId: campaignId,
            adSpaceId: adSpaceId,
            publisherId: publisherId,
            eventType: Self.IMPRESSION,
            origin: domain,
            apiKey: apiKey,
            bidId: bidId,
            bidMeta: bidMeta,
            buyType: buyType,
            isTestEnvironment: isTestEnvironment,
            additionalProperties: properties
        ) { result in
            print("\(Self.TAG): Impression event result: \(result ?? "nil")")
        }
    }
    
    // Track view event (scroll depth, visibility ratio, view time)
    public func trackView(
        campaignId: String,
        adSpaceId: String,
        publisherId: String,
        apiKey: String,
        bidId: String,
        bidMeta: String,
        buyType: String,
        isTestEnvironment: Bool,
        viewTime: Float,
        visibilityRatio: Float,
        scrollDepth: Float,
        timeToVisible: Float
    ) {
        let properties: [String: Any] = [
            "viewTime": viewTime,
            "visibilityRatio": visibilityRatio,
            "scrollDepth": scrollDepth,
            "timeToVisible": timeToVisible
        ]
        
        sendTrackingData(
            campaignId: campaignId,
            adSpaceId: adSpaceId,
            publisherId: publisherId,
            eventType: Self.VIEW,
            origin: domain,
            apiKey: apiKey,
            bidId: bidId,
            bidMeta: bidMeta,
            buyType: buyType,
            isTestEnvironment: isTestEnvironment,
            additionalProperties: properties
        ) { result in
            print("\(Self.TAG): View event result: \(result ?? "nil")")
        }
    }
    
    // Track total view time
    public func trackTotalView(
        campaignId: String,
        adSpaceId: String,
        publisherId: String,
        apiKey: String,
        bidId: String,
        bidMeta: String,
        buyType: String,
        isTestEnvironment: Bool,
        totalViewTime: Float,
        visibilityRatio: Float
    ) {
        let properties: [String: Any] = [
            "totalViewTime": totalViewTime,
            "visibilityRatio": visibilityRatio
        ]
        
        sendTrackingData(
            campaignId: campaignId,
            adSpaceId: adSpaceId,
            publisherId: publisherId,
            eventType: Self.TOTAL_VIEW,
            origin: domain,
            apiKey: apiKey,
            bidId: bidId,
            bidMeta: bidMeta,
            buyType: buyType,
            isTestEnvironment: isTestEnvironment,
            additionalProperties: properties
        ) { result in
            print("\(Self.TAG): Total view event result: \(result ?? "nil")")
        }
    }
    
    // Track click
    public func trackClick(
        campaignId: String,
        adSpaceId: String,
        publisherId: String,
        apiKey: String,
        bidId: String,
        bidMeta: String,
        buyType: String,
        isTestEnvironment: Bool
    ) {
        let properties: [String: Any] = [:]
        
        sendTrackingData(
            campaignId: campaignId,
            adSpaceId: adSpaceId,
            publisherId: publisherId,
            eventType: Self.CLICK,
            origin: domain,
            apiKey: apiKey,
            bidId: bidId,
            bidMeta: bidMeta,
            buyType: buyType,
            isTestEnvironment: isTestEnvironment,
            additionalProperties: properties
        ) { result in
            print("\(Self.TAG): Click event result: \(result ?? "nil")")
        }
    }
    
    // Track video playback
    public func trackVideoPlayback(
        campaignId: String,
        adSpaceId: String,
        publisherId: String,
        apiKey: String,
        bidId: String,
        bidMeta: String,
        buyType: String,
        isTestEnvironment: Bool,
        totalPlaybackTime: Float
    ) {
        let properties: [String: Any] = [
            "totalPlaybackTime": totalPlaybackTime
        ]
        
        sendTrackingData(
            campaignId: campaignId,
            adSpaceId: adSpaceId,
            publisherId: publisherId,
            eventType: Self.VIDEO_PLAYBACK,
            origin: domain,
            apiKey: apiKey,
            bidId: bidId,
            bidMeta: bidMeta,
            buyType: buyType,
            isTestEnvironment: isTestEnvironment,
            additionalProperties: properties
        ) { result in
            print("\(Self.TAG): Video playback event result: \(result ?? "nil")")
        }
    }
    
    // Track video quartile
    public func trackVideoQuartile(
        campaignId: String,
        adSpaceId: String,
        publisherId: String,
        apiKey: String,
        bidId: String,
        bidMeta: String,
        buyType: String,
        isTestEnvironment: Bool,
        quartile: String
    ) {
        let properties: [String: Any] = [
            "quartile": quartile
        ]
        
        sendTrackingData(
            campaignId: campaignId,
            adSpaceId: adSpaceId,
            publisherId: publisherId,
            eventType: Self.VIDEO_QUARTILE,
            origin: domain,
            apiKey: apiKey,
            bidId: bidId,
            bidMeta: bidMeta,
            buyType: buyType,
            isTestEnvironment: isTestEnvironment,
            additionalProperties: properties
        ) { result in
            print("\(Self.TAG): Video quartile event result: \(result ?? "nil")")
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