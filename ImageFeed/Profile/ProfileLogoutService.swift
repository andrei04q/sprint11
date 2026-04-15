import Foundation
import WebKit

final class ProfileLogoutService {
    static let shared = ProfileLogoutService()
    
    private init() { }
    
    func logout() {
        cleanOAuthToken()
        cleanCookies()
        cleanServices()
        moveToInitialScreen()
    }
    
    private func cleanOAuthToken() {
        OAuth2TokenStorage.shared.token = nil
    }
    
    private func cleanCookies() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records) {}
        }
    }
    
    private func cleanServices() {
        ProfileService.shared.cleanProfile()
        ProfileImageService.shared.cleanAvatar()
        ImagesListService.shared.reset()
    }
    
    private func moveToInitialScreen() {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let sceneDelegate = windowScene.delegate as? SceneDelegate,
                  let window = sceneDelegate.window else { return }
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let authVC = storyboard.instantiateViewController(withIdentifier: "AuthViewController") as? UIViewController {
                window.rootViewController = authVC
            } else if let loginVC = storyboard.instantiateInitialViewController() {
                window.rootViewController = loginVC
            } else {
                let navController = UINavigationController()
                window.rootViewController = navController
            }
            
            window.makeKeyAndVisible()
        }
    }
}
