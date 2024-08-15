import Foundation
import UIKit

struct UIHelper {
    static var activeWindow: UIWindow? {
        let windows = UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
        return windows.first { $0.isKeyWindow } ?? windows.first
    }

    static var topViewController: UIViewController? {
        guard var topController = Self.activeWindow?.rootViewController else {
            return nil
        }

        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }

        return topController
    }
}
