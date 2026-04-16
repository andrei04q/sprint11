import UIKit

final class SplashViewController: UIViewController {

    private let profileService = ProfileService.shared
    private let storage = OAuth2TokenStorage.shared

    private var imageView: UIImageView!

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        setupImageView()

        guard let token = storage.token else {
            presentAuthViewController()
            return
        }

        fetchProfile(token: token)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    private func setupImageView() {
        let imageSplashScreenLogo = UIImage(named: "SplashScreen")
        imageView = UIImageView(image: imageSplashScreenLogo)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func presentAuthViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)

        guard let vc = storyboard.instantiateViewController(
            withIdentifier: "AuthViewController"
        ) as? AuthViewController else {
            assertionFailure("AuthViewController not found")
            return
        }

        vc.delegate = self
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }

    private func switchToTabBarController() {
        guard let window = UIApplication.shared.windows.first else {
            assertionFailure("No window")
            return
        }

        let tabBar = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController")

        window.rootViewController = tabBar
    }

    private func fetchProfile(token: String) {
        UIBlockingProgressHUD.show()

        profileService.fetchProfile(token) { [weak self] result in
            UIBlockingProgressHUD.dismiss()

            guard let self else { return }

            switch result {
            case .success(let profile):
                ProfileImageService.shared.fetchProfileImageURL(
                    username: profile.username
                ) { _ in }

                self.switchToTabBarController()

            case .failure(let error):
                print("[Splash] profile error: \(error)")
            }
        }
    }
}

extension SplashViewController: AuthViewControllerDelegate {
    func didAuthenticate(_ vc: AuthViewController) {
        vc.dismiss(animated: true)

        if let token = storage.token {
            fetchProfile(token: token)
        }
    }
}
