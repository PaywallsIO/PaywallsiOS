import Foundation
import UIKit

protocol InternalPropertiesProtocol {
    var eventProperties: [String: PaywallsValueTypeProtocol] { get }
    var setOnceProperties: [String: PaywallsValueTypeProtocol] { get }
    var appUserProperties: [String: PaywallsValueTypeProtocol] { get }
}

final class InternalProperties: InternalPropertiesProtocol {
    private let sessionManager: SessionManagerProtocol

    private static let screenHeight = "$screen_height"
    private static let screenWidth = "$screen_width"
    private static let os = "$os"
    private static let osVersion = "$os_version"
    private static let bundleIdentifier = "$identifier"
    private static let appVersion = "$app_version"
    private static let appBuildNumber = "$app_build_number"
    private static let lib = "$lib"
    private static let libVersion = "$lib_version"
    private static let manufacturer = "$manufacturer"
    private static let deviceModel = "$device_model"
    private static let email = "$email"
    private static let duration = "$duration"
    private static let sessionId = "$session_id"

    private static let iosBuildNumber = "$ios_build_number"
    private static let iosAppVersion = "$ios_app_version"
    private static let iosDeviceModel = "$ios_device_model"
    private static let iosVersion = "$ios_version"
    private static let iosLibVersion = "$ios_lib_version"
    private static let firstSeen = "$first_seen"
    private static let firstSeenLib = "$first_seen_lib"
    private static let firstSeenVersion = "$first_seen_version"

    init(sessionManager: SessionManagerProtocol) {
        self.sessionManager = sessionManager
    }

    var eventProperties: [String: PaywallsValueTypeProtocol] {
        var properties = [String: PaywallsValueTypeProtocol]()

        properties[Self.os] = UIDevice.current.systemName
        properties[Self.osVersion] = UIDevice.current.systemVersion
        properties[Self.manufacturer] = "Apple"
        properties[Self.lib] = "swift"
        properties[Self.deviceModel] = rawDeviceName
        properties[Self.bundleIdentifier] = Bundle.main.bundleIdentifier
        properties[Self.libVersion] = Definitions.libVersion
        if let session = sessionManager.sessionId {
            properties[Self.sessionId] = session
        }

        let screenSize = UIScreen.main.bounds.size
        properties[Self.screenHeight] = String(Int(screenSize.height))
        properties[Self.screenWidth] = String(Int(screenSize.width))

        let infoDict = Bundle.main.infoDictionary ?? [:]
        if let build = infoDict["CFBundleVersion"] as? String {
            properties[Self.appBuildNumber] = build
        }
        if let version = infoDict["CFBundleShortVersionString"] as? String {
            properties[Self.appVersion] = version
        }

        return properties
    }

    var setOnceProperties: [String: PaywallsValueTypeProtocol] {
        var properties = [String: PaywallsValueTypeProtocol]()
        properties[Self.firstSeen] = Date().ISO8601Format()
        properties[Self.bundleIdentifier] = Bundle.main.bundleIdentifier
        properties[Self.firstSeenLib] = "swift"

        let infoDict = Bundle.main.infoDictionary ?? [:]
        if let version = infoDict["CFBundleShortVersionString"] as? String {
            properties[Self.firstSeenVersion] = version
        }

        return properties
    }

    var appUserProperties: [String: PaywallsValueTypeProtocol] {
        var properties = [String: PaywallsValueTypeProtocol]()

        properties[Self.iosLibVersion] = Definitions.libVersion
        properties[Self.iosDeviceModel] = rawDeviceName
        properties[Self.iosVersion] = UIDevice.current.systemVersion

        let infoDict = Bundle.main.infoDictionary ?? [:]
        if let version = infoDict["CFBundleShortVersionString"] as? String {
            properties[Self.iosAppVersion] = version
        }
        if let build = infoDict["CFBundleVersion"] as? String {
            properties[Self.iosBuildNumber] = build
        }

        return properties
    }

    private var rawDeviceName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
}
