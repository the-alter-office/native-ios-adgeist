import Foundation
import Network

public class FetchCreative {
    private let adgeistCore: AdgeistCore
    private static let TAG = "FetchCreative"
    
    init(adgeistCore: AdgeistCore) {
        self.adgeistCore = adgeistCore
    }
    
    public func fetchCreative(
        adUnitID: String,
        buyType: String,
        isTestEnvironment: Bool = true,
        completion: @escaping (Any?) -> Void
    ) {
        print("\(Self.TAG): Fetching creative for Ad Unit ID: \(adUnitID), Buy Type: \(buyType), Test Environment: \(isTestEnvironment)")
        adgeistCore.deviceIdentifier.getDeviceIdentifier { deviceId in         
            let userIP = self.adgeistCore.networkUtils.getLocalIpAddress() ?? self.adgeistCore.networkUtils.getWifiIpAddress() ?? "unknown"
            let envFlag = isTestEnvironment ? "1" : "0"
            
            let urlString: String
            if buyType == "FIXED" {
                urlString = "\(self.adgeistCore.bidRequestBackendDomain)/v2/dsp/ad/fixed"
            } else {
                urlString = "\(self.adgeistCore.bidRequestBackendDomain)/v1/app/ssp/bid?adSpaceId=\(adUnitID)&companyId=\(self.adgeistCore.adgeistAppID)&test=\(envFlag)"
            }
            
            print("\(Self.TAG): Request URL--------------------------: \(urlString)")

            guard let url = URL(string: urlString) else {
                completion(nil)
                return
            }
            
            var payload: [String: Any] = [:]
            
        //    if let targetingInfo = self.adgeistCore.targetingInfo {
        //        payload["device"] = targetingInfo["meta"] ?? [:]
        //    }
            
            if buyType == "FIXED" {
                payload["platform"] = "IOS"
                payload["deviceId"] = deviceId
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
                print("\(Self.TAG): Request Body--------------------------: \(bodyString)")
            }
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("\(Self.TAG): Failed to request ad: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("\(Self.TAG): HTTP Status Code--------------------------: \(httpResponse.statusCode)")
                    
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
                    completion(nil)
                    return
                }
                
                if let rawResponse = String(data: data, encoding: .utf8) {
                    print("\(Self.TAG): Raw Response: \(rawResponse)")
                }
                
                let adData = self.parseCreativeData(from: data, buyType: buyType)
                
                if let adData = adData, self.isEmptyCreative(adData) {
                    completion(nil)
                    return
                }
                
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
                return fixedData
            } else {
                let cpmData = try decoder.decode(CPMAdResponse.self, from: data)
                return cpmData
            }
        } catch let DecodingError.dataCorrupted(context) {
            return nil
        } catch let DecodingError.keyNotFound(key, context) {
            return nil
        } catch let DecodingError.valueNotFound(value, context) {
            return nil
        } catch let DecodingError.typeMismatch(type, context) {
            return nil
        } catch {
            return nil
        }
    }
}

