import Foundation

public class CreativeAnalytics {
    private let adgeistCore: AdgeistCore
    private static let TAG = "CreativeAnalytics"
    
    init(adgeistCore: AdgeistCore) {
        self.adgeistCore = adgeistCore
    }

    public func sendTrackingDataV2(analyticsRequest: AnalyticsRequest) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            let urlString = "https://\(self.adgeistCore.bidRequestBackendDomain)/v2/ssp/impression"
            
            guard let url = URL(string: urlString) else { return }
            
            guard let jsonData = try? analyticsRequest.toJsonData() else { return }
            
            if let bodyString = String(data: jsonData, encoding: .utf8) {
                print("Request Body--------------------------: \(bodyString)")
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = jsonData
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("\(Self.TAG): Failed to send tracking data: \(error.localizedDescription)")
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("\(Self.TAG): HTTP Status Code--------------------------: \(httpResponse.statusCode)")
                    
                    guard httpResponse.statusCode == 200 else {
                        var errorMessage = "HTTP Error: Status code \(httpResponse.statusCode)"
                        
                        if let data = data, let responseString = String(data: data, encoding: .utf8) {
                            errorMessage += " - Response: \(responseString)"
                        }
                        
                        print(errorMessage)
                        return
                    }
                }
                
                guard let data = data else {
                    return
                }
                
                if let rawResponse = String(data: data, encoding: .utf8) {
                    print("\(Self.TAG): Raw Response: \(rawResponse)")
                }
            }
            task.resume()
        }
    }

    public func sendTrackingData(analyticsRequestDEPRECATED: AnalyticsRequestDEPRECATED) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            let envFlag = analyticsRequestDEPRECATED.isTestMode ? "1" : "0"
            
            let urlString: String
            if analyticsRequestDEPRECATED.buyType == "FIXED" {
                urlString = "https://\(self.adgeistCore.bidRequestBackendDomain)/v2/ssp/impression"
            } else {
                urlString = "https://\(self.adgeistCore.bidRequestBackendDomain)/api/analytics/track?adSpaceId=\(analyticsRequestDEPRECATED.adUnitID)&companyId=\(self.adgeistCore.adgeistAppID)&test=\(envFlag)"
            }
            
            self.adgeistCore.deviceIdentifier.getDeviceIdentifier { [weak self] deviceId in
                guard let self = self else { return }
                
                let userIP = self.adgeistCore.networkUtils.getLocalIpAddress() ?? self.adgeistCore.networkUtils.getWifiIpAddress() ?? "unknown"
                
                guard let url = URL(string: urlString) else {
                    print("\(Self.TAG): Invalid URL: \(urlString)")
                    return
                }
                
                guard let jsonData = try? analyticsRequestDEPRECATED.toJsonData() else {
                    print("\(Self.TAG): Failed to serialize JSON")
                    return
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.httpBody = jsonData
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                
                if analyticsRequestDEPRECATED.buyType != "FIXED" {
                    request.addValue(self.adgeistCore.packageOrBundleID, forHTTPHeaderField: "Origin")
                    request.addValue(deviceId, forHTTPHeaderField: "x-user-id")
                    request.addValue("mobile_app", forHTTPHeaderField: "x-platform")
                    request.addValue(self.adgeistCore.apiKey, forHTTPHeaderField: "x-api-key")
                    request.addValue(userIP, forHTTPHeaderField: "x-forwarded-for")
                }
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        print("\(Self.TAG): Failed to send tracking data: \(error.localizedDescription)")
                        return
                    }
                    
                    if let httpResponse = response as? HTTPURLResponse, !((200...299).contains(httpResponse.statusCode)) {
                        let errorBody = String(data: data ?? Data(), encoding: .utf8) ?? "No error message"
                        print("\(Self.TAG): Request failed with code: \(httpResponse.statusCode), message: \(errorBody)")
                        return
                    }
                    
                    let jsonString = String(data: data ?? Data(), encoding: .utf8)
                    print("\(Self.TAG): Tracking data sent successfully: \(jsonString ?? "")")
                }
                task.resume()
            }
        }
    }
}
