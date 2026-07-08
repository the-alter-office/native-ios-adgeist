import Foundation
import Network

public class FetchCreative {
    private let adgeistCore: AdgeistCore
    private static let TAG = "FetchCreative"
    
    init(adgeistCore: AdgeistCore) {
        self.adgeistCore = adgeistCore
    }
    
    private func getCurrentUTCTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }
    
    public func fetchCreative(
        adUnitID: String,
        buyType: String,
        isTestEnvironment: Bool = true,
        completion: @escaping (AdData) -> Void
    ) {
        print("\(Self.TAG): Fetching creative for Ad Unit ID: \(adUnitID), Buy Type: \(buyType), Test Environment: \(isTestEnvironment)")
        adgeistCore.deviceIdentifier.getDeviceIdentifier { deviceId in         
            let envFlag = isTestEnvironment ? "1" : "0"
            let urlString: String
            urlString = "\(self.adgeistCore.bidRequestBackendDomain)/v2/dsp/ad"
           
            print("\(Self.TAG): Request URL--------------------------: \(urlString) , \(self.adgeistCore.version)")
            guard let url = URL(string: urlString) else {
                completion(AdData(data: nil, error: AdVisibilityError(errorMessage: "Invalid URL"), statusCode: nil))
                return
            }
            let requestBuilder = FetchCreativeRequest.FetchCreativeRequestBuilder(
                adSpaceId: adUnitID,
                companyId: self.adgeistCore.adgeistAppID,
                isTest: isTestEnvironment
            )
            if let targetingInfo = self.adgeistCore.targetingInfo {
                if let deviceMetrics = targetingInfo["deviceTargetingMetrics"] as? [String: Any] {
                    requestBuilder.setDevice(deviceMetrics)
                }
            }
            
            let currentTimestamp = self.getCurrentUTCTimestamp()
            requestBuilder
                .setPlatform("IOS")
                .setDeviceId(deviceId)
                .setTimeZone(TimeZone.current.identifier)
                .setRequestedAt(currentTimestamp)
                .setSdkVersion(self.adgeistCore.version)
           
            let fetchCreativeRequest = requestBuilder.build()
            let payload = fetchCreativeRequest.toJson()
            guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
                completion(AdData(data: nil, error: AdVisibilityError(errorMessage: "Failed to encode request payload"), statusCode: nil))
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = jsonData
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(self.adgeistCore.packageOrBundleID, forHTTPHeaderField: "Origin")
            if let bodyString = String(data: jsonData, encoding: .utf8) {
                print("\(Self.TAG): Request Body--------------------------: \(bodyString)")
            }
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("\(Self.TAG): Failed to request ad: \(error.localizedDescription)")
                    completion(AdData(data: nil, error: AdVisibilityError(errorMessage: error.localizedDescription), statusCode: nil))
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
                        completion(AdData(data: nil, error: AdVisibilityError(errorMessage: errorMessage), statusCode: httpResponse.statusCode))
                        return
                    }
                }
                guard let data = data else {
                    completion(AdData(data: nil, error: AdVisibilityError(errorMessage: "No data in response"), statusCode: nil))
                    return
                }
                if let rawResponse = String(data: data, encoding: .utf8) {
                    print("\(Self.TAG): Raw Response: \(rawResponse)")
                }
                let adData = self.parseCreativeData(from: data)
                if let adData = adData, self.isEmptyCreative(adData) {
                    completion(AdData(data: nil, error: AdVisibilityError(errorMessage: "No valid ad creative available"), statusCode: (response as? HTTPURLResponse)?.statusCode))
                    return
                }
                if let adData = adData as? AdResponseData {
                    completion(AdData(data: adData, error: nil, statusCode: (response as? HTTPURLResponse)?.statusCode))
                } else {
                    completion(AdData(data: nil, error: AdVisibilityError(errorMessage: "Failed to parse creative data"), statusCode: (response as? HTTPURLResponse)?.statusCode))
                }
            }
            task.resume()
        }
    }
    
    private func isEmptyCreative(_ ad: Any) -> Bool {
        if let fixedAd = ad as? FixedAdResponse {
            return fixedAd.id.isEmpty ||
                   fixedAd.campaignId?.isEmpty ?? true ||
                   fixedAd.advertiser == nil
        }
        return false
    }
    
    private func parseCreativeData(from data: Data) -> Any? {
        do {
            let decoder = JSONDecoder()
            let res = try decoder.decode(FixedAdResponse.self, from: data)
            return res
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

