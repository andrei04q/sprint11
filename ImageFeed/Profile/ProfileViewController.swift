import UIKit
import Kingfisher

final class ProfileViewController: UIViewController, ProfileViewControllerProtocol {
    
    // MARK: - Dependencies
    private var presenter: ProfilePresenterProtocol!
    
    func configure(_ presenter: ProfilePresenterProtocol) {
        self.presenter = presenter
        presenter.view = self
    }
    
    // MARK: - UI
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "avatar")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 35
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Екатерина Новикова"
        label.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "@ekaterina_nov"
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor(named: "YP Gray") ?? .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Hello, world!"
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let logoutProfileButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "logoutProfileButton"), for: .normal)
        button.tintColor = UIColor(named: "YP Red") ?? .systemRed
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var profileImageServiceObserver: NSObjectProtocol?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print(">>> ProfileViewController загружен!")
        view.backgroundColor = UIColor(named: "YP Black (iOS)")
        nameLabel.accessibilityIdentifier = "profileNameLabel"
        usernameLabel.accessibilityIdentifier = "profileLoginLabel"
        logoutProfileButton.accessibilityIdentifier = "logoutButton"
        
        [avatarImageView, nameLabel, usernameLabel, descriptionLabel, logoutProfileButton].forEach {
            view.addSubview($0)
        }
        
        applyConstraints()
        
        if presenter == nil {
            let presenter = ProfilePresenter()
            configure(presenter)
        }
        
        logoutProfileButton.addTarget(
            self,
            action: #selector(didTaplogoutProfileButton),
            for: .touchUpInside
        )
        
        profileImageServiceObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main,
            using: { [weak self] _ in
                self?.presenter.viewDidLoad()
            }
        )
        
        presenter.viewDidLoad()
    }
    
    deinit {
        if let observer = profileImageServiceObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Actions
    @objc func didTaplogoutProfileButton() {
        presenter.didTapLogout()
    }
    
    // MARK: - ProfileViewControllerProtocol
    func updateProfileDetails(name: String, login: String, bio: String?) {
        nameLabel.text = name.isEmpty ? "Имя не указано" : name
        usernameLabel.text = login.isEmpty ? "@неизвестный_пользователь" : login
        descriptionLabel.text = (bio?.isEmpty ?? true) ? "Профиль не заполнен" : bio
    }
    
    func updateAvatar(url: URL?) {
        guard let url else {
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
            return
        }
        
        let placeholderImage = UIImage(systemName: "person.circle.fill")?
            .withTintColor(.lightGray, renderingMode: .alwaysOriginal)
            .withConfiguration(
                UIImage.SymbolConfiguration(
                    pointSize: 70,
                    weight: .regular,
                    scale: .large
                )
            )
        
        let processor = RoundCornerImageProcessor(cornerRadius: 35)
        
        avatarImageView.kf.indicatorType = .activity
        avatarImageView.kf.setImage(
            with: url,
            placeholder: placeholderImage,
            options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .cacheOriginalImage,
                .forceRefresh
            ]
        ) { result in
            switch result {
            case let .success(value):
                print("Image loaded from: \(value.source)")
            case let .failure(error):
                print("Failed to load image: \(error)")
            }
        }
    }
    
    func showLogoutAlert() {
        let alert = UIAlertController(
            title: "Пока, пока!",
            message: "Уверены, что хотите выйти?",
            preferredStyle: .alert
        )
        let logoutAction = UIAlertAction(title: "Да", style: .default) { _ in
            ProfileLogoutService.shared.logout()
        }
        let cancelAction = UIAlertAction(title: "Нет", style: .cancel)
        
        alert.addAction(logoutAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    // MARK: - Layout
    private func applyConstraints() {
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            avatarImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            avatarImageView.widthAnchor.constraint(equalToConstant: 70),
            avatarImageView.heightAnchor.constraint(equalToConstant: 70),
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            usernameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            usernameLabel.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            logoutProfileButton.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            logoutProfileButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            logoutProfileButton.widthAnchor.constraint(equalToConstant: 44),
            logoutProfileButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
}
