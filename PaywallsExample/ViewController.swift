import UIKit
import Paywalls

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        PaywallsSDK.shared.trigger("test", presentingViewController: self)
    }
}

