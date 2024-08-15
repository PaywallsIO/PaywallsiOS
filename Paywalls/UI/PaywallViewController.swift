import UIKit
import WebKit
import SwiftUI
import Combine

protocol PaywallViewModelProtocol: ObservableObject {
    var state: PaywallState { get set }
    var statePublisher: Published<PaywallState>.Publisher { get }

    func didBind()
}

class PaywallViewController<ViewModel: PaywallViewModelProtocol>: UIViewController {
    private let viewModel: ViewModel
    private var webView: WKWebView!
    private var skeletonView: UIView!
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        webView = WKWebView(frame: .zero)
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        skeletonView = UIHostingController(rootView: SkeltonView()).view
        skeletonView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(skeletonView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            skeletonView.topAnchor.constraint(equalTo: view.topAnchor),
            skeletonView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            skeletonView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            skeletonView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        webView.publisher(for: \.isLoading)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.toggleSkeltonView(isLoading: isLoading)
            }
            .store(in: &cancellables)

        viewModel.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .loading:
                    self?.toggleSkeltonView(isLoading: true)
                case let .result(url):
                    self?.webView.load(URLRequest(url: url))
                }
            }
            .store(in: &cancellables)

        viewModel.didBind()
    }

    private func toggleSkeltonView(isLoading: Bool) {
        UIView.animate(withDuration: 0.2, animations: {
            self.skeletonView.layer.opacity = isLoading ? 1 : 0
        })
    }
}
