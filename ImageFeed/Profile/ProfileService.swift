import Foundation

final class ProfileService {
    static let shared = ProfileService()
    private init() { }

    private var task: URLSessionTask?
    private let urlSession = URLSession.shared
    private(set) var profile: Profile?

    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        task?.cancel()

        guard let request = makeProfileRequest(token: token) else {
            completion(.failure(URLError(.badURL)))
            return
        }

        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }

            if let jsonString = String(data: data, encoding: .utf8) {
                print("Полученный JSON профиля: \(jsonString)")
            }

            do {
                let profile = try self?.createProfile(from: data)
                if let profile = profile {
                    self?.profile = profile
                    DispatchQueue.main.async {
                        completion(.success(profile))
                    }
                } else {
                    throw URLError(.badServerResponse)
                }
            } catch {
                print("[fetchProfile]: Ошибка декодирования: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        self.task = task
        task.resume()
    }

    private func createProfile(from data: Data) throws -> Profile {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let result = try decoder.decode(ProfileResult.self, from: data)

        let nameToShow: String
        if let name = result.name, !name.isEmpty {
            nameToShow = name
        } else {
            let fullName = [result.firstName, result.lastName]
                .compactMap { $0 }
                .joined(separator: " ")
            nameToShow = fullName.isEmpty ? "Имя не указано" : fullName
        }

        let username = result.username ?? ""
        return Profile(
            username: username,
            name: nameToShow,
            loginName: username.isEmpty ? "@неизвестный_пользователь" : "@\(username)",
            bio: result.bio
        )
    }

    private func makeProfileRequest(token: String) -> URLRequest? {
        guard let url = URL(string: Constants.unsplashProfileURLString) else {
            print("Failed to create profile URL")
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    func cleanProfile() {
        profile = nil
    }
}
