//
//  FetchCreative.swift
//  AdgeistKit
//
//  Created by kishore on 02/05/25.
//

import Foundation
import Network

public class FetchCreative {
    private let deviceIdentifier: DeviceIdentifier
    
    init(deviceIdentifier: DeviceIdentifier) {
        self.deviceIdentifier = deviceIdentifier
    }
    
    public func fetchCreative(
        apiKey: String,
        origin: String,
        adSpaceId: String,
        companyId: String,
        isTestEnvironment: Bool = true,
        completion: @escaping (CreativeDataModel?) -> Void
    ) {
        deviceIdentifier.getDeviceIdentifier { deviceId in
            print("Device ID: \(deviceId)")
            
            let userIP = self.getLocalIPAddress() ?? "unknown"
            let envFlag = isTestEnvironment ? "1" : "0"
            let urlString = "https://bg-services-api.adgeist.ai/app/ssp/bid?adSpaceId=\(adSpaceId)&companyId=\(companyId)&test=\(envFlag)"
            
            print("Request URL: \(urlString)")

            guard let url = URL(string: urlString) else {
                completion(nil)
                return
            }
            
            // Prepare JSON body
            let jsonBody: [String: Any] = [
                "appDto": [
                    "name": "itwcrm",
                    "bundle": "com.itwcrm"
                ]
            ]
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonBody) else {
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
            
            // Debug request
            print("Request URL: \(urlString)")
            print("Request Headers: \(request.allHTTPHeaderFields ?? [:])")
            if let bodyString = String(data: jsonData, encoding: .utf8) {
                print("Request Body: \(bodyString)")
            }
            print("Device ID: \(deviceId)")
            print("User IP: \(userIP)")
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Request Failed: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                // Debug HTTP response
                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Status Code: \(httpResponse.statusCode)")
                    print("HTTP Headers: \(httpResponse.allHeaderFields)")
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
                
                let adData = self.parseCreativeData(from: data)
                print("Parsed Response: \(String(describing: adData))")
                completion(adData)
            }
            
            task.resume()
        }
    }
    
    private func parseCreativeData(from data: Data) -> CreativeDataModel? {
        do {
            let decoder = JSONDecoder()
            let creativeData = try decoder.decode(CreativeDataModel.self, from: data)
            print("Successfully parsed creative data: \(creativeData)")
            return creativeData
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

