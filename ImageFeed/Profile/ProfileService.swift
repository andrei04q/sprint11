import Foundation

final class ProfileService {

    static let shared = ProfileService()
    private init() {}

    private var task: URLSessionTask?
    private let urlSession = URLSession.shared

    private(set) var profile: Profile?

    // MARK: - Public

    func fetchProfile(_ token: String,
                      completion: @escaping (Result<Profile, Error>) -> Void) {

        task?.cancel()

        guard let request = makeProfileRequest(token: token) else {
            print("[ProfileService] ❌ invalid request")
            completion(.failure(URLError(.badURL)))
            return
        }

        print("[ProfileService] 📡 fetching profile...")

        let task = urlSession.dataTask(with: request) { [weak self] data, _, error in

            if let error {
                print("[ProfileService] ❌ network error: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let data else {
                print("[ProfileService] ❌ empty response")
                DispatchQueue.main.async {
                    completion(.failure(URLError(.badServerResponse)))
                }
                return
            }

            do {
                let profile = try self?.createProfile(from: data)

                guard let profile else {
                    throw URLError(.badServerResponse)
                }

                DispatchQueue.main.async {
                    self?.profile = profile
                    completion(.success(profile))
                }

            } catch {
                print("[ProfileService] ❌ decode error: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }

        self.task = task
        task.resume()
    }

    // MARK: - Clean (ВАЖНО ДЛЯ LOGOUT)

    func cleanProfile() {
        profile = nil
        task?.cancel()
        task = nil
    }

    // MARK: - Private

    private func makeProfileRequest(token: String) -> URLRequest? {
        guard let url = URL(string: Constants.unsplashProfileURLString) else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return request
    }

    private func createProfile(from data: Data) throws -> Profile {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let result = try decoder.decode(ProfileResult.self, from: data)

        let name: String = {
            if let name = result.name, !name.isEmpty {
                return name
            }

            let full = [result.firstName, result.lastName]
                .compactMap { $0 }
                .joined(separator: " ")

            return full.isEmpty ? "Имя не указано" : full
        }()

        let username = result.username ?? ""

        return Profile(
            username: username,
            name: name,
            loginName: username.isEmpty ? "@unknown" : "@\(username)",
            bio: result.bio
        )
    }
}
