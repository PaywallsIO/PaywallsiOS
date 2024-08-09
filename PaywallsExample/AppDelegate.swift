import UIKit
import Paywalls

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let config = PaywallsConfig(apiKey: "1|ci3D6KbbqPsEC22gAbziyiznwL6HK41aI7Hr6GGH70c1946e")
        config.logLevel = .verbose
        PaywallsSDK.setup(config: config)

        PaywallsSDK.shared.reset()
        PaywallsSDK.shared.capture("Test Event", [
            "test": "value"
        ])
        PaywallsSDK.shared.identify("TestUser")
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

