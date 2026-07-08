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

    public func getOSVersion() -> Int {
        Int(UIDevice.current.systemVersion.split(separator: ".").first ?? "0") ?? 0
    }

    public func getScreenDimensions() -> [String: Int] {
        let s = UIScreen.main.bounds
        return ["width": Int(s.width), "height": Int(s.height)]
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

    public func isTouchScreenAvailable() -> Bool { true }

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

    public func isVrCapable() -> Bool {
        let motion = CMMotionManager()
        return motion.isDeviceMotionAvailable
    }

    public func isScreenReaderPresent() -> Bool {
        UIAccessibility.isVoiceOverRunning
    }

    public func getDeviceAge() -> String? { nil }

    public func getDevicePricing() -> String? { nil }

    public func getAllDeviceInfo() -> [String: Any] {
        let dims = getScreenDimensions()

        return [
            "deviceType": getDeviceType(),
            "deviceBrand": getDeviceBrand(),
            "cpuType": getCpuType(),
            "architecture": getCoreArchitecture(),
            "availableProcessors": getAvailableProcessors(),

            "operatingSystem": getOperatingSystem(),
            "osVersion": getOSVersion(),

            "screenDimensions": dims,

            "networkType": getNetworkType() as Any,
            "networkProvider": getNetworkProvider() as Any,

            "isTouchScreenAvailable": isTouchScreenAvailable(),
            "isGpuCapable": isGpuCapable(),
            "isNfcCapable": isNfcCapable(),
            "isVrCapable": isVrCapable(),
            "isScreenReaderPresent": isScreenReaderPresent(),

            "deviceAge": NSNull(),
            "devicePricing": NSNull()
        ]
    }
}
