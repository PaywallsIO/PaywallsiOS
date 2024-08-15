import Foundation
import UIKit

protocol PaywallCoordinatorProtocol {
    func instinateRoot() -> UIViewController
}

final class PaywallCoordinator: PaywallCoordinatorProtocol {
    private let container: PaywallsContainer
    private let triggerFire: TriggerFire

    init(container: PaywallsContainer, triggerFire: TriggerFire) {
        self.container = container
        self.triggerFire = triggerFire
    }

    func instinateRoot() -> UIViewController {
        let viewModel = container.makePaywallViewModel(
            coordinator: self,
            triggerFire: triggerFire
        )
        return PaywallViewController(viewModel: viewModel)
    }
}
