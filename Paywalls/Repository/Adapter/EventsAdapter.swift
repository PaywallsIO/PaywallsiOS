import Foundation

struct EventsAdapter {
    static func toTriggerFile(_ from: TriggerResponse) -> TriggerFire? {
        guard let paywallUrl = URL(string: from.paywall.url) else { return nil }
        return .init(
            paywallName: from.paywall.name,
            paywallUrl: paywallUrl
        )
    }
}
