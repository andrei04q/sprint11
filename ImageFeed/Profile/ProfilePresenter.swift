import Foundation

final class ProfilePresenter: ProfilePresenterProtocol {
    weak var view: ProfileViewControllerProtocol?
    
    private let profileService: ProfileService
    private let imageService: ProfileImageService
    private let tokenStorage: OAuth2TokenStorage
    
    init(profileService: ProfileService = .shared,
         imageService: ProfileImageService = .shared,
         tokenStorage: OAuth2TokenStorage = .shared) {
        self.profileService = profileService
        self.imageService = imageService
        self.tokenStorage = tokenStorage
    }
    
    func viewDidLoad() {
        loadProfile()
        loadAvatar()
    }
    
    func didTapLogout() {
        view?.showLogoutAlert()
    }
    
    // MARK: - Private
    
    private func loadProfile() {
        guard let token = tokenStorage.token else { return }
        
        profileService.fetchProfile(token) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case let .success(profile):
                DispatchQueue.main.async {
                    self.view?.updateProfileDetails(
                        name: profile.name,
                        login: profile.loginName,
                        bio: profile.bio
                    )
                }
            case let .failure(error):
                print("Не удалось получить профиль:", error)
            }
        }
    }
    
    private func loadAvatar() {
        guard let urlString = imageService.avatarURL,
              let url = URL(string: urlString) else {
            view?.updateAvatar(url: nil)
            return
        }
        view?.updateAvatar(url: url)
    }
}
