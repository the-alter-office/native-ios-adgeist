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
            let urlString = "\(self.adgeistCore.bidRequestBackendDomain)/v2/ssp/impression"
            
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
}
