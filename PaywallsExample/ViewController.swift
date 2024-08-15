import UIKit
import Paywalls

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        PaywallsSDK.shared.trigger("test", presentingViewController: self)
    }
}

