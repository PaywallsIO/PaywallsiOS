import Foundation

enum PaywallState {
    case loading
    case result(url: URL)
}

final class PaywallViewModel: PaywallViewModelProtocol {
    private let coordinator: PaywallCoordinatorProtocol
    private let triggerFire: TriggerFire

    @Published var state: PaywallState = .loading
    var statePublisher: Published<PaywallState>.Publisher { $state }

    init(
        coordinator: PaywallCoordinatorProtocol,
        triggerFire: TriggerFire
    ) {
        self.coordinator = coordinator
        self.triggerFire = triggerFire
    }

    func didBind() {
        state = .result(url: triggerFire.paywallUrl)
    }
}
