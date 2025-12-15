import Foundation
import Network

public class FetchCreative {
    private let adgeistCore: AdgeistCore
    
    init(adgeistCore: AdgeistCore) {
        self.adgeistCore = adgeistCore
    }
    
    public func fetchCreative(
        adUnitID: String,
        buyType: String,
        isTestEnvironment: Bool = true,
        completion: @escaping (Any?) -> Void
    ) {
        adgeistCore.deviceIdentifier.getDeviceIdentifier { deviceId in         
            let userIP = self.adgeistCore.networkUtils.getLocalIpAddress() ?? self.adgeistCore.networkUtils.getWifiIpAddress() ?? "unknown"
            let envFlag = isTestEnvironment ? "1" : "0"
            
            let urlString: String
            if buyType == "FIXED" {
                urlString = "https://\(self.adgeistCore.bidRequestBackendDomain)/v2/dsp/ad/fixed"
            } else {
                urlString = "https://\(self.adgeistCore.bidRequestBackendDomain)/v1/app/ssp/bid?adSpaceId=\(adUnitID)&companyId=\(self.adgeistCore.adgeistAppID)&test=\(envFlag)"
            }
            
            print("Request URL: \(urlString)")

            guard let url = URL(string: urlString) else {
                completion(nil)
                return
            }
            
            var payload: [String: Any] = [:]
            
//            if let targetingInfo = self.adgeistCore.targetingInfo {
//                payload["device"] = targetingInfo["meta"] ?? [:]
//            }
            
            if buyType == "FIXED" {
                payload["adspaceId"] = adUnitID
                payload["companyId"] = self.adgeistCore.adgeistAppID
                payload["timeZone"] = TimeZone.current.identifier
            } else {
                payload["appDto"] = [
                    "name": "itwcrm",
                    "bundle": "com.itwcrm"
                ]
            }
            
            payload["origin"] = self.adgeistCore.packageOrBundleID
            payload["isTest"] = isTestEnvironment
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
                completion(nil)
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = jsonData
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if buyType != "FIXED" {
                request.addValue(self.adgeistCore.packageOrBundleID, forHTTPHeaderField: "Origin")
                request.addValue(deviceId, forHTTPHeaderField: "x-user-id")
                request.addValue("mobile_app", forHTTPHeaderField: "x-platform")
                request.addValue(self.adgeistCore.apiKey, forHTTPHeaderField: "x-api-key")
                request.addValue(userIP, forHTTPHeaderField: "x-forwarded-for")
            }
            
            if let bodyString = String(data: jsonData, encoding: .utf8) {
                print("Request Body: \(bodyString)")
            }
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Request Failed: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Status Code: \(httpResponse.statusCode)")
                    
                    guard httpResponse.statusCode == 200 else {
                        var errorMessage = "HTTP Error: Status code \(httpResponse.statusCode)"
                        
                        if let data = data, let responseString = String(data: data, encoding: .utf8) {
                            errorMessage += " - Response: \(responseString)"
                        }
                        
                        print(errorMessage)
                        completion(nil)
                        return
                    }
                }
                
                guard let data = data else {
                    print("No data received")
                    completion(nil)
                    return
                }
                
                if let rawResponse = String(data: data, encoding: .utf8) {
                    print("Raw Response: \(rawResponse)")
                }
                
                let adData = self.parseCreativeData(from: data, buyType: buyType)
                
                if let adData = adData, self.isEmptyCreative(adData) {
                    print("Creative is empty, returning nil")
                    completion(nil)
                    return
                }
                
                print("Parsed Response: \(String(describing: adData))")
                completion(adData)
            }
            
            task.resume()
        }
    }
    
    private func isEmptyCreative(_ ad: Any) -> Bool {
        if let fixedAd = ad as? FixedAdResponse {
            return fixedAd.id.isEmpty || 
                   fixedAd.campaignId?.isEmpty ?? true || 
                   fixedAd.advertiser == nil
        } else if let cpmAd = ad as? CPMAdResponse {
            return cpmAd.data?.seatBid.isEmpty ?? true
        }
        return false
    }
    
    private func parseCreativeData(from data: Data, buyType: String) -> Any? {
        do {
            let decoder = JSONDecoder()
            if buyType == "FIXED" {
                let fixedData = try decoder.decode(FixedAdResponse.self, from: data)
                print("Successfully parsed fixed ad data: \(fixedData)")
                return fixedData
            } else {
                let cpmData = try decoder.decode(CPMAdResponse.self, from: data)
                print("Successfully parsed CPM ad data: \(cpmData)")
                return cpmData
            }
        } catch let DecodingError.dataCorrupted(context) {
            print("JSON parsing failed - Data corrupted: \(context)")
            return nil
        } catch let DecodingError.keyNotFound(key, context) {
            print("JSON parsing failed - Key '\(key)' not found: \(context.debugDescription)")
            print("codingPath: \(context.codingPath)")
            return nil
        } catch let DecodingError.valueNotFound(value, context) {
            print("JSON parsing failed - Value '\(value)' not found: \(context.debugDescription)")
            print("codingPath: \(context.codingPath)")
            return nil
        } catch let DecodingError.typeMismatch(type, context) {
            print("JSON parsing failed - Type '\(type)' mismatch: \(context.debugDescription)")
            print("codingPath: \(context.codingPath)")
            return nil
        } catch {
            print("JSON parsing failed with unknown error: \(error.localizedDescription)")
            return nil
        }
    }
}

