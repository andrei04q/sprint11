import UIKit

protocol AuthViewControllerDelegate: AnyObject {
    func didAuthenticate(_ vc: AuthViewController)
}

final class AuthViewController: UIViewController {

    private let showWebViewSegueIdentifier = "ShowWebView"
    private let oauth2Service = OAuth2Service.shared

    weak var delegate: AuthViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackButton()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showWebViewSegueIdentifier {

            guard let webVC = segue.destination as? WebViewViewController else {
                assertionFailure("Failed to prepare WebViewViewController")
                return
            }

            let authHelper = AuthHelper()
            let presenter = WebViewPresenter(authHelper: authHelper)

            presenter.view = webVC
            webVC.presenter = presenter
            webVC.delegate = self

        } else {
            super.prepare(for: segue, sender: sender)
        }
    }

    private func configureBackButton() {
        navigationController?.navigationBar.backIndicatorImage = UIImage(named: "nav_back_button")
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "nav_back_button")

        navigationItem.backBarButtonItem = UIBarButtonItem(
            title: "",
            style: .plain,
            target: nil,
            action: nil
        )

        navigationItem.backBarButtonItem?.tintColor = UIColor(named: "ypBlack")
    }

    private func showAuthErrorAlert() {
        let alert = UIAlertController(
            title: AuthStrings.Alert.errorTitle,
            message: AuthStrings.Alert.errorMessage,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(
            title: AuthStrings.Alert.okButton,
            style: .default
        ))

        present(alert, animated: true)
    }
}

// MARK: - WebView delegate
extension AuthViewController: WebViewViewControllerDelegate {

    func webViewViewController(_ vc: WebViewViewController,
                               didAuthenticateWithCode code: String) {

        vc.dismiss(animated: true)
        UIBlockingProgressHUD.show()

        oauth2Service.fetchOAuthToken(code) { [weak self] result in
            UIBlockingProgressHUD.dismiss()

            guard let self else { return }

            switch result {
            case .success(let token):
                print("✅ Auth success token: \(token.prefix(20))...")

                OAuth2TokenStorage.shared.token = token

                // ВАЖНО: только делегат, без переходов тут
                self.delegate?.didAuthenticate(self)

            case .failure(let error):
                print("❌ Auth error: \(error.localizedDescription)")
                self.showAuthErrorAlert()
            }
        }
    }

    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        vc.dismiss(animated: true)
    }
}
