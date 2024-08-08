import Foundation
import UIKit

enum InternalProperty: String {
    case screenHeight = "$screen_height"
    case screenWidth = "$screen_width"
    case os = "$os"
    case osVersion = "$os_version"
    case bundleIdentifier = "$identifier"
    case appVersion = "$app_version"
    case appBuildNumber = "$app_build_number"
    case lib = "$lib"
    case libVersion = "$lib_version"
    case manufacturer = "$manufacturer"
    case deviceModel = "$device_model"
    case email = "$email"
    case duration = "$duration"

    case iosBuildNumber = "$ios_build_number"
    case iosAppVersion = "$ios_app_version"
    case iosDeviceModel = "$ios_device_model"
    case iosVersion = "$ios_version"
    case iosLibVersion = "$ios_lib_version"
    case firstSeen = "$first_seen"
    case firstSeenLib = "$first_seen_lib"
    case firstSeenVersion = "$first_seen_version"

    static var eventProperties: [String: PaywallsValueType] = {
        var properties = [String: PaywallsValueTypeProtocol]()

        properties[Self.os.rawValue] = UIDevice.current.systemName
        properties[Self.osVersion.rawValue] = UIDevice.current.systemVersion
        properties[Self.manufacturer.rawValue] = "Apple"
        properties[Self.lib.rawValue] = "swift"
        properties[Self.deviceModel.rawValue] = rawDeviceName
        properties[Self.bundleIdentifier.rawValue] = Bundle.main.bundleIdentifier
        properties[Self.libVersion.rawValue] = Definitions.libVersion

        let screenSize = UIScreen.main.bounds.size
        properties[Self.screenHeight.rawValue] = String(Int(screenSize.height))
        properties[Self.screenWidth.rawValue] = String(Int(screenSize.width))

        let infoDict = Bundle.main.infoDictionary ?? [:]
        if let build = infoDict["CFBundleVersion"] as? String {
            properties[Self.appBuildNumber.rawValue] = build
        }
        if let version = infoDict["CFBundleShortVersionString"] as? String {
            properties[Self.appVersion.rawValue] = version
        }

        return properties.mapValues({ PaywallsValueType(value: $0) })
    }()

    static var setOnceProperties: [String: PaywallsValueTypeProtocol] = {
        var properties = [String: PaywallsValueTypeProtocol]()
        properties[Self.firstSeen.rawValue] = Date().ISO8601Format()
        properties[Self.bundleIdentifier.rawValue] = Bundle.main.bundleIdentifier
        properties[Self.firstSeenLib.rawValue] = "swift"

        let infoDict = Bundle.main.infoDictionary ?? [:]
        if let version = infoDict["CFBundleShortVersionString"] as? String {
            properties[Self.firstSeenVersion.rawValue] = version
        }

        return properties
    }()

    static var appUserProperties: [String: PaywallsValueTypeProtocol] = {
        var properties = [String: PaywallsValueTypeProtocol]()

        properties[Self.iosLibVersion.rawValue] = Definitions.libVersion
        properties[Self.iosDeviceModel.rawValue] = rawDeviceName
        properties[Self.iosVersion.rawValue] = UIDevice.current.systemVersion

        let infoDict = Bundle.main.infoDictionary ?? [:]
        if let version = infoDict["CFBundleShortVersionString"] as? String {
            properties[Self.iosAppVersion.rawValue] = version
        }
        if let build = infoDict["CFBundleVersion"] as? String {
            properties[Self.iosBuildNumber.rawValue] = build
        }

        return properties
    }()

    private static var rawDeviceName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
}
