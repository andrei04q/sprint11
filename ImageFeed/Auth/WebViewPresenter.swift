import UIKit
import WebKit

final class WebViewPresenter: WebViewPresenterProtocol {
    weak var view: WebViewViewControllerProtocol?
    weak var delegate: WebViewViewControllerDelegate?
    private let authHelper: AuthHelperProtocol
    
    init(authHelper: AuthHelperProtocol) {
        self.authHelper = authHelper
    }
    
    func viewDidLoad() {
        guard let request = authHelper.authRequest() else { return }
        view?.load(request: request)
        didUpdateProgress(0.0)
    }
    
    func shouldHideProgress(for value: Float) -> Bool {
        fabsf(value - 1.0) <= 0.0001
    }
    
    func didUpdateProgress(_ newValue: Double) {
        let progress = Float(newValue)
        view?.setProgressValue(progress)
        let shouldHide = shouldHideProgress(for: progress)
        view?.setProgressHidden(shouldHide)
    }
    
    func decidePolicy(for navigationAction: WKNavigationAction,
                      decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url,
              let code = authHelper.code(from: url) else {
            decisionHandler(.allow)
            return
        }
        
        print("✅ CODE FOUND: \(code)")
        print("Delegate: \(delegate != nil ? "OK" : "NIL!")")
        
        if let vc = view as? WebViewViewController {
            delegate?.webViewViewController(vc, didAuthenticateWithCode: code)
        }
        decisionHandler(.cancel)
    }
}
