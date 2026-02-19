import Foundation

class FetchCreativeRequest {
    // Required
    private let adSpaceId: String
    private let companyId: String
    private let isTest: Bool
    
    // Optional
    private let platform: String?
    private let deviceId: String?
    private let timeZone: String?
    private let requestedAt: String?
    private let sdkVersion: String?
    private let device: [String: Any]?
    private let appDto: [String: String]?
    
    private init(builder: FetchCreativeRequestBuilder) {
        self.adSpaceId = builder.adSpaceId
        self.companyId = builder.companyId
        self.isTest = builder.isTest
        self.platform = builder.platform
        self.deviceId = builder.deviceId
        self.timeZone = builder.timeZone
        self.requestedAt = builder.requestedAt
        self.sdkVersion = builder.sdkVersion
        self.device = builder.device
        self.appDto = builder.appDto
    }
    
    class FetchCreativeRequestBuilder {
        // Required
        internal let adSpaceId: String
        internal let companyId: String
        internal let isTest: Bool
        
        // Optional
        var platform: String?
        var deviceId: String?
        var timeZone: String?
        var requestedAt: String?
        var sdkVersion: String?
        var device: [String: Any]?
        var appDto: [String: String]?
        
        init(adSpaceId: String, companyId: String, isTest: Bool) {
            self.adSpaceId = adSpaceId
            self.companyId = companyId
            self.isTest = isTest
        }
        
        func setPlatform(_ platform: String) -> FetchCreativeRequestBuilder {
            self.platform = platform
            return self
        }
        
        func setDeviceId(_ deviceId: String) -> FetchCreativeRequestBuilder {
            self.deviceId = deviceId
            return self
        }
        
        func setTimeZone(_ timeZone: String) -> FetchCreativeRequestBuilder {
            self.timeZone = timeZone
            return self
        }
        
        func setRequestedAt(_ requestedAt: String) -> FetchCreativeRequestBuilder {
            self.requestedAt = requestedAt
            return self
        }
        
        func setSdkVersion(_ sdkVersion: String) -> FetchCreativeRequestBuilder {
            self.sdkVersion = sdkVersion
            return self
        }
        
        func setDevice(_ device: [String: Any]) -> FetchCreativeRequestBuilder {
            self.device = device
            return self
        }
        
        func setAppDto(appName: String, appBundle: String) -> FetchCreativeRequestBuilder {
            self.appDto = [
                "name": appName,
                "bundle": appBundle
            ]
            return self
        }
        
        func build() -> FetchCreativeRequest {
            return FetchCreativeRequest(builder: self)
        }
    }
    
    func toJson() -> [String: Any] {
        var json: [String: Any] = [:]
        
        json["isTest"] = isTest
        
        if let device = device {
            json["device"] = device
        }
        
        if let platform = platform {
            json["platform"] = platform
        }
        
        if let deviceId = deviceId {
            json["deviceId"] = deviceId
        }
        
        json["adspaceId"] = adSpaceId
        json["companyId"] = companyId
        
        if let timeZone = timeZone {
            json["timeZone"] = timeZone
        }
        
        if let requestedAt = requestedAt {
            json["requestedAt"] = requestedAt
        }
        
        if let sdkVersion = sdkVersion {
            json["sdkVersion"] = sdkVersion
        }
        
        if let appDto = appDto {
            json["appDto"] = appDto
        }
        
        return json
    }
    
    func getAdSpaceId() -> String {
        return adSpaceId
    }
    
    func getCompanyId() -> String {
        return companyId
    }
    
    func isTestEnvironment() -> Bool {
        return isTest
    }
}
