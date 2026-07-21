import UIKit
import CoreTelephony
import CoreMotion
import Metal
import CoreNFC

public final class DeviceMeta {
    public func getDeviceType() -> String {
        UIDevice.current.userInterfaceIdiom == .tv ? "DESKTOP" : "MOBILE"
    }

    public func getDeviceBrand() -> String { "Apple" }

    public func getCpuType() -> String? {
        return "Unknown"
    }

    public func getCoreArchitecture() -> String {
        #if arch(arm64)
        return "ARM64"
        #elseif arch(arm)
        return "ARM"
        #elseif arch(x86_64)
        return "x86-64"
        #elseif arch(i386)
        return "x86"
        #else
        return "Unknown"
        #endif
    }

    public func getAvailableProcessors() -> Int {
        ProcessInfo.processInfo.activeProcessorCount
    }

    public func getOperatingSystem() -> String { "IOS" }

    public func getOSVersion() -> String {
        String(Int(UIDevice.current.systemVersion.split(separator: ".").first ?? "0") ?? 0)
    }

    public func getScreenDimensions() -> (width: Int, height: Int) {
        let bounds = UIScreen.main.bounds
        let scale = UIScreen.main.scale
        return (Int(bounds.width * scale), Int(bounds.height * scale))
    }

    public func getScreenPixelRatio() -> Float {
        Float(UIScreen.main.scale)
    }

    public func getScreenDensity() -> Int {
        Int(UIScreen.main.scale * 160)
    }

    public func getNetworkType() -> String? {
        guard let info = CTTelephonyNetworkInfo() as CTTelephonyNetworkInfo?,
              let tech = info.serviceCurrentRadioAccessTechnology?.values.first else {
            return nil
        }

        switch tech {
        case CTRadioAccessTechnologyGPRS,
             CTRadioAccessTechnologyEdge,
             CTRadioAccessTechnologyWCDMA,
             CTRadioAccessTechnologyHSDPA,
             CTRadioAccessTechnologyHSUPA,
             CTRadioAccessTechnologyCDMA1x,
             CTRadioAccessTechnologyCDMAEVDORev0,
             CTRadioAccessTechnologyCDMAEVDORevA,
             CTRadioAccessTechnologyCDMAEVDORevB,
             CTRadioAccessTechnologyeHRPD:
            return "3G"

        case CTRadioAccessTechnologyLTE:
            return "4G"

        case CTRadioAccessTechnologyNRNSA,
             CTRadioAccessTechnologyNR:
            return "5G"

        default:
            return "Unknown"
        }
    }

    public func getNetworkProvider() -> String? {
        let info = CTTelephonyNetworkInfo()
        return info.serviceSubscriberCellularProviders?.values.first?.carrierName
    }

    public func isTouchScreenCapable() -> Bool { true }

    public func isGpuCapable() -> Bool {
        if #available(iOS 13.0, *) {
            return MTLCreateSystemDefaultDevice() != nil
        }
        return true
    }

    public func isNfcCapable() -> Bool {
        if #available(iOS 11.0, *) {
            return NFCNDEFReaderSession.readingAvailable
        }
        return false
    }

    public func isNFCEnabled() -> Bool {
        isNfcCapable()
    }

    public func isVrCapable() -> Bool {
        let motion = CMMotionManager()
        return motion.isDeviceMotionAvailable
    }

    public func isScreenReaderPresent() -> Bool {
        UIAccessibility.isVoiceOverRunning
    }

    public func getAllDeviceInfo() -> [String: Any] {
        let (width, height) = getScreenDimensions()

        return [
            "deviceType": getDeviceType(),
            "deviceBrand": getDeviceBrand(),

            "screenWidth": width,
            "screenHeight": height,
            "screenPixelRatio": getScreenPixelRatio(),
            "screenDensity": getScreenDensity(),

            "osName": getOperatingSystem(),
            "osVersion": getOSVersion(),

            "supportedArchitectures": getCpuType() as Any,
            "architecture": getCoreArchitecture(),
            "noOfProcessors": getAvailableProcessors(),

            "networkType": getNetworkType() as Any,
            "networkConnectionType": getNetworkProvider() as Any,

            "isScreenReaderEnabled": isScreenReaderPresent(),
            "isNfcCapable": isNfcCapable(),
            "isNfcEnabled": isNFCEnabled(),
            "isVrCapable": isVrCapable(),

            "isGpuCapable": isGpuCapable(),
            "isTouchScreenCapable": isTouchScreenCapable()
        ]
    }
}
