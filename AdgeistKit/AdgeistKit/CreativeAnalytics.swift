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
        completion: @escaping (String?) -> Void
    ) {
        deviceIdentifier.getDeviceIdentifier { deviceId in
            print("Successfully fetched Device ID: \(deviceId)")
            
            let urlString = "https://beta-api.adgeist.ai/campaign/campaign-analytics?campaignId=\(campaignId)&adSpaceId=\(adSpaceId)&companyId=\(publisherId)"
            guard let url = URL(string: urlString) else {
                completion(nil)
                return
            }
            
            var requestBody: [String: Int] = [:]
            switch eventType.lowercased() {
            case "click":
                requestBody["clicks"] = 1
            case "impression":
                requestBody["impressions"] = 1
            default:
                break
            }
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
                completion(nil)
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.addValue("https://beta.adgeist.ai", forHTTPHeaderField: "Origin")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
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
                    print("Request failed with code: \(httpResponse.statusCode)")
                    completion(nil)
                    return
                }
                
                if let data = data, let jsonString = String(data: data, encoding: .utf8) {
                    completion(jsonString)
                } else {
                    completion(nil)
                }
            }
            
            task.resume()
        }
    }
}
