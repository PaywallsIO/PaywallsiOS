import SwiftUI
import UIKit

// Todo: experimental. Remove if not using
struct PaywallsScreen<ViewModel: PaywallViewModelProtocol>: View {
    @StateObject private var viewModel: ViewModel

    static func makeViewController(viewModel: ViewModel) -> UIViewController {
        let view = PaywallsScreen(viewModel: viewModel)
        return UIHostingController(rootView: view)
    }

    init(viewModel: ViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case let .result(url):
            WebView(url: url, navigationDelegate: nil)
        }
    }
}
