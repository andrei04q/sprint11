import Foundation

struct ProfileImage: Codable {
    let small: String
    let medium: String
    let large: String
}

struct UserResult: Codable {
    let profileImage: ProfileImage

    private enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}

final class ProfileImageService {

    static let shared = ProfileImageService()
    private init() {}

    static let didChangeNotification = Notification.Name("ProfileImageServiceDidChange")

    private(set) var avatarURL: String?
    private var task: URLSessionTask?

    func fetchProfileImageURL(username: String,
                              completion: @escaping (Result<String, Error>) -> Void) {

        task?.cancel()

        guard let token = OAuth2TokenStorage.shared.token else {
            print("[ProfileImageService] failure: missing token")
            completion(.failure(URLError(.userAuthenticationRequired)))
            return
        }

        guard let request = makeProfileImageRequest(username: username, token: token) else {
            print("[ProfileImageService] failure: invalid request")
            completion(.failure(URLError(.badURL)))
            return
        }

        let task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<UserResult, Error>) in

            DispatchQueue.main.async {
                guard let self else { return }

                switch result {

                case let .success(result):

                    let url = result.profileImage.small
                    self.avatarURL = url

                    NotificationCenter.default.post(
                        name: ProfileImageService.didChangeNotification,
                        object: self,
                        userInfo: ["URL": url]
                    )

                    print("[ProfileImageService] success")
                    completion(.success(url))

                case let .failure(error):

                    print("[ProfileImageService] failure: \(error)")
                    completion(.failure(error))
                }
            }
        }

        self.task = task
        task.resume()
    }

    private func makeProfileImageRequest(username: String,
                                         token: String) -> URLRequest? {

        guard let url = URL(string: "https://api.unsplash.com/users/\(username)") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return request
    }

    func cleanAvatar() {
        avatarURL = nil
        task?.cancel()
        task = nil
    }
}
