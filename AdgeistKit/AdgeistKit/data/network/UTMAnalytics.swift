import Foundation

/// Handles sending UTM tracking data to the backend analytics API
public class UTMAnalytics {
    private let bidRequestBackendDomain: String
    private static let TAG = "UTMAnalytics"
    private static let ANALYTICS_ENDPOINT = "/v2/ssp/campaign-event"
    
    init(bidRequestBackendDomain: String) {
        self.bidRequestBackendDomain = bidRequestBackendDomain
    }
    
    /// Send UTM parameters to backend API
    public func sendUtmData(
        _ params: UTMParameters,
        eventType: String = EventTypes.VISIT,
        additionalData: [String: Any]? = nil,
        onComplete: ((Bool, String?) -> Void)? = nil
    ) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let url = "\(self.bidRequestBackendDomain)\(Self.ANALYTICS_ENDPOINT)"
                
                // Create JSON payload with UTM parameters
                let payload = self.buildPayload(params: params, eventType: eventType, additionalData: additionalData)
                let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
                
                guard let requestUrl = URL(string: url) else {
                    let errorMessage = "Invalid URL: \(url)"
                    print("\(Self.TAG): \(errorMessage)")
                    onComplete?(false, errorMessage)
                    return
                }
                
                var request = URLRequest(url: requestUrl)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = jsonData
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        let errorMessage = "Failed to send UTM data to backend: \(error.localizedDescription)"
                        print("\(Self.TAG): \(errorMessage)")
                        onComplete?(false, errorMessage)
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        let errorMessage = "Invalid response type"
                        print("\(Self.TAG): \(errorMessage)")
                        onComplete?(false, errorMessage)
                        return
                    }
                    
                    if httpResponse.statusCode != 200 {
                        let errorBody = data.flatMap { String(data: $0, encoding: .utf8) } ?? "No error message"
                        let errorMessage = "UTM API request failed with code: \(httpResponse.statusCode), message: \(errorBody)"
                        print("\(Self.TAG): \(errorMessage)")
                        onComplete?(false, errorMessage)
                        return
                    }
                    
                    print("\(Self.TAG): UTM data sent successfully to backend")
                    onComplete?(true, nil)
                }
                
                task.resume()
                
            } catch {
                let errorMessage = "Error sending UTM data to backend: \(error.localizedDescription)"
                print("\(Self.TAG): \(errorMessage)")
                onComplete?(false, errorMessage)
            }
        }
    }
    
    /// Send an install attribution event (first launch only)
    public func sendInstallAttributionEvent(utmParameters: UTMParameters?) {
        let eventType = utmParameters != nil ? EventTypes.INSTALL : EventTypes.INSTALL_ORGANIC
        
        if let params = utmParameters {
            sendUtmData(params, eventType: eventType) { success, error in
                let attribution = utmParameters != nil ? "attributed" : "organic"
                if success {
                    print("\(Self.TAG): INSTALL event sent - \(attribution)")
                } else {
                    print("\(Self.TAG): INSTALL event failed - \(attribution), error: \(error ?? "unknown")")
                }
            }
        } else {
            // For organic installs, create empty UTM parameters
            let emptyParams = UTMParameters()
            sendUtmData(emptyParams, eventType: eventType) { success, error in
                if success {
                    print("\(Self.TAG): INSTALL event sent - organic")
                } else {
                    print("\(Self.TAG): INSTALL event failed - organic, error: \(error ?? "unknown")")
                }
            }
        }
    }
    
    // MARK: - Private Helpers
    
    /// Build JSON payload for UTM tracking
    private func buildPayload(params: UTMParameters, eventType: String, additionalData: [String: Any]? = nil) -> [String: Any] {
        var payload: [String: Any] = [
            "metaData": params.data ?? "",
            "flowId": params.sessionId ?? "",
            "type": eventType,
            "origin": params.source ?? "",
            "platform": "IOS"
        ]
        
        // Add additional data if provided
        if let additionalData = additionalData {
            payload["additionalData"] = additionalData
        }
        
        return payload
    }
}
