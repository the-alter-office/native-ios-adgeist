import Foundation
import Network

public class FetchCreative {
    private let deviceIdentifier: DeviceIdentifier
    private let domain: String
    private let targetingInfo: [String: Any]?
    
    init(deviceIdentifier: DeviceIdentifier, domain: String, targetingInfo: [String: Any]?) {
        self.deviceIdentifier = deviceIdentifier
        self.domain = domain
        self.targetingInfo = targetingInfo
    }
    
    public func fetchCreative(
        apiKey: String,
        origin: String,
        adSpaceId: String,
        companyId: String,
        buyType: String,
        isTestEnvironment: Bool = true,
        completion: @escaping (Any?) -> Void
    ) {
        deviceIdentifier.getDeviceIdentifier { deviceId in
            print("Device ID: \(deviceId)")
            
            let userIP = self.getLocalIPAddress() ?? "unknown"
            let envFlag = isTestEnvironment ? "1" : "0"
            
            let urlString: String
            if buyType == "FIXED" {
                urlString = "https://\(self.domain)/v2/dsp/ad/fixed"
            } else {
                urlString = "https://\(self.domain)/v1/app/ssp/bid?adSpaceId=\(adSpaceId)&companyId=\(companyId)&test=\(envFlag)"
            }
            
            print("Request URL: \(urlString)")

            guard let url = URL(string: urlString) else {
                completion(nil)
                return
            }
            
            // Prepare JSON body
            var payload: [String: Any] = [:]
            
            if let targetingInfo = self.targetingInfo {
                payload["device"] = self.targetingInfo ?? [:]
            }
            
            if buyType == "FIXED" {
                payload["adspaceId"] = adSpaceId
                payload["companyId"] = companyId
                payload["timeZone"] = TimeZone.current.identifier
                payload["origin"] = origin
            } else {
                payload["appDto"] = [
                    "name": "itwcrm",
                    "bundle": "com.itwcrm"
                ]
            }
            
            payload["origin"] = origin
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
                request.addValue(origin, forHTTPHeaderField: "Origin")
                request.addValue(deviceId, forHTTPHeaderField: "x-user-id")
                request.addValue("mobile_app", forHTTPHeaderField: "x-platform")
                request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
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
                
                // Debug HTTP response
                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Status Code: \(httpResponse.statusCode)")
                    
                    guard httpResponse.statusCode == 200 else {
                        print("HTTP Error: Status code \(httpResponse.statusCode)")
                        completion(nil)
                        return
                    }
                }
                
                guard let data = data else {
                    print("No data received")
                    completion(nil)
                    return
                }
                
                // Debug raw response
                if let rawResponse = String(data: data, encoding: .utf8) {
                    print("Raw Response: \(rawResponse)")
                }
                
                let adData = self.parseCreativeData(from: data, buyType: buyType)
                
                // Check if creative is empty
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

