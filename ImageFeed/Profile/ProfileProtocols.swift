import Foundation

protocol ProfileViewControllerProtocol: AnyObject {
    func updateProfileDetails(name: String, login: String, bio: String?)
    func updateAvatar(url: URL?)
    func showLogoutAlert()
}

protocol ProfilePresenterProtocol: AnyObject {
    var view: ProfileViewControllerProtocol? { get set }
    func viewDidLoad()
    func didTapLogout()
}
