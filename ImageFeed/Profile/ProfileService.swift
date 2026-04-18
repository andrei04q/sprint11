import Foundation

final class ProfileService {

    static let shared = ProfileService()
    private init() {}

    private var task: URLSessionTask?
    private let urlSession = URLSession.shared

    private(set) var profile: Profile?

    func fetchProfile(_ token: String,
                      completion: @escaping (Result<Profile, Error>) -> Void) {

        task?.cancel()

        guard let request = makeProfileRequest(token: token) else {
            print("[ProfileService] failure: invalid request")
            completion(.failure(URLError(.badURL)))
            return
        }

        let task = urlSession.dataTask(with: request) { [weak self] data, _, error in

            DispatchQueue.main.async {
                guard let self else { return }

                if let error {
                    print("[ProfileService] failure: \(error)")
                    completion(.failure(error))
                    return
                }

                guard let data else {
                    print("[ProfileService] failure: empty response")
                    completion(.failure(URLError(.badServerResponse)))
                    return
                }

                do {
                    let profile = try self.createProfile(from: data)
                    self.profile = profile

                    print("[ProfileService] success")
                    completion(.success(profile))

                } catch {
                    print("[ProfileService] failure: \(error)")
                    completion(.failure(error))
                }
            }
        }

        self.task = task
        task.resume()
    }

    func cleanProfile() {
        profile = nil
        task?.cancel()
        task = nil
    }

    private func makeProfileRequest(token: String) -> URLRequest? {
        guard let url = URL(string: Constants.unsplashProfileURLString) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return request
    }

    private func createProfile(from data: Data) throws -> Profile {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let result = try decoder.decode(ProfileResult.self, from: data)

        let name = result.name ?? ""
        let username = result.username ?? ""

        return Profile(
            username: username,
            name: name.isEmpty ? "Name not specified" : name,
            loginName: username.isEmpty ? "@unknown" : "@\(username)",
            bio: result.bio
        )
    }
}
