import Foundation
import UIKit

protocol InternalPropertiesProtocol {
    var eventProperties: [String: PaywallsValueTypeProtocol] { get }
}

final class InternalProperties: InternalPropertiesProtocol {
    private let sessionManager: SessionManagerProtocol
    private let reachability: ReachabilityManagerProtocol

    static let screenHeight = "$screen_height"
    static let screenWidth = "$screen_width"
    static let os = "$os"
    static let osVersion = "$os_version"
    static let bundleIdentifier = "$app_namespace"
    static let appVersion = "$app_version"
    static let appBuildNumber = "$app_build_number"
    static let lib = "$lib"
    static let libVersion = "$lib_version"
    static let manufacturer = "$manufacturer"
    static let deviceModel = "$device_model"
    static let deviceName = "$device_name"
    static let deviceType = "$device_type"
    static let email = "$email"
    static let duration = "$duration"
    static let sessionId = "$session_id"
    static let anonDistinctId = "$anon_distinct_id"
    static let appName = "$app_name"
    static let locale = "$locale"
    static let ip = "$ip"
    static let networkWifi = "$network_wifi"
    static let networkCellular = "$network_cellular"
    static let sessionDurationSeconds = "$session_duration_seconds"

    init(sessionManager: SessionManagerProtocol, reachability: ReachabilityManagerProtocol) {
        self.sessionManager = sessionManager
        self.reachability = reachability
    }

    var eventProperties: [String: PaywallsValueTypeProtocol] {
        var properties = [String: PaywallsValueTypeProtocol]()

        properties[Self.sessionDurationSeconds] = sessionManager.secondsSinceSessionStart
        properties[Self.manufacturer] = "Apple"
        properties[Self.lib] = "swift"
        properties[Self.deviceModel] = platform()
        properties[Self.bundleIdentifier] = Bundle.main.bundleIdentifier
        properties[Self.libVersion] = Definitions.libVersion
        if let ip = ipaddress() {
            properties[Self.ip] = ip
        }
        if Locale.current.languageCode != nil {
            properties[Self.locale] = Locale.current.languageCode
        }
        if let session = sessionManager.sessionId {
            properties[Self.sessionId] = session
        }

        let infoDict = Bundle.main.infoDictionary ?? [:]
        if let appName = infoDict[kCFBundleNameKey as String] as? String {
            properties[Self.appName] = appName
        } else if let appName = infoDict["CFBundleDisplayName"] as? String {
            properties[Self.appName] = appName
        }
        if let build = infoDict["CFBundleVersion"] as? String {
            properties[Self.appBuildNumber] = build
        }
        if let version = infoDict["CFBundleShortVersionString"] as? String {
            properties[Self.appVersion] = version
        }

#if os(iOS) || os(tvOS)
        let screenSize = UIScreen.main.bounds.size
        properties[Self.screenHeight] = String(Int(screenSize.height))
        properties[Self.screenWidth] = String(Int(screenSize.width))

        let device = UIDevice.current
        // use https://github.com/devicekit/DeviceKit
        properties[Self.deviceName] = device.model
        properties[Self.os] = device.systemName
        properties[Self.osVersion] = device.systemVersion

        var deviceType: String?
        switch device.userInterfaceIdiom {
        case UIUserInterfaceIdiom.phone:
            deviceType = "Mobile"
        case UIUserInterfaceIdiom.pad:
            deviceType = "Tablet"
        case UIUserInterfaceIdiom.tv:
            deviceType = "TV"
        case UIUserInterfaceIdiom.carPlay:
            deviceType = "CarPlay"
        case UIUserInterfaceIdiom.mac:
            deviceType = "Desktop"
        default:
            deviceType = nil
        }
        if deviceType != nil {
            properties[Self.deviceType] = deviceType
        }
#elseif os(macOS)
        if let mainScreen = NSScreen.main {
            let screenFrame = mainScreen.visibleFrame
            properties[Self.screenWidth] = Float(screenFrame.size.width)
            properties[Self.screenHeight] = Float(screenFrame.size.height)
        }

        let deviceName = Host.current().localizedName
        if (deviceName?.isEmpty) != nil {
            properties[Self.deviceName] = deviceName
        }
        let processInfo = ProcessInfo.processInfo
        properties[Self.os] = "macOS \(processInfo.operatingSystemVersionString)" // eg Version 14.2.1 (Build 23C71)
        let osVersion = processInfo.operatingSystemVersion
        properties[Self.osVersion] = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        properties[Self.deviceType] = "Desktop"
#endif

        properties[Self.networkWifi] = reachability.isWifi
        properties[Self.networkCellular] = reachability.isCellular

        return properties
    }

    func ipaddress() -> String? {
        var address : String?

        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }

        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee

            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {

                // Check interface name:
                // wifi = ["en0"]
                // wired = ["en2", "en3", "en4"]
                // cellular = ["pdp_ip0","pdp_ip1","pdp_ip2","pdp_ip3"]

                let name = String(cString: interface.ifa_name)
                if  name == "en0" || name == "en2" || name == "en3" || name == "en4" || name == "pdp_ip0" || name == "pdp_ip1" || name == "pdp_ip2" || name == "pdp_ip3" {

                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)

        return address
    }

    private func platform() -> String {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
    }
}
