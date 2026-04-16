import Foundation

enum AuthServiceError: Error {
    case invalidRequest
    case noAccessToken
}

final class OAuth2Service {
    static let shared = OAuth2Service()

    private let dataStorage = OAuth2TokenStorage.shared
    private let urlSession = URLSession.shared

    private var task: URLSessionTask?
    private var isFetching = false

    private(set) var authToken: String? {
        get { dataStorage.token }
        set { dataStorage.token = newValue }
    }

    private init() {}

    func fetchOAuthToken(_ code: String,
                         completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)

        task?.cancel()
        task = nil

        guard let request = makeOAuthTokenRequest(code: code) else {
            print("[OAuth2Service] ❌ Invalid request")
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }

        print("[OAuth2Service] 📡 Fetch token started")

        let task = urlSession.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self else { return }

                if let error {
                    print("[OAuth2Service] ❌ Network error: \(error)")
                    completion(.failure(error))
                    return
                }

                guard let data else {
                    print("[OAuth2Service] ❌ Empty response")
                    completion(.failure(AuthServiceError.invalidRequest))
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase

                    let body = try decoder.decode(OAuthTokenResponseBody.self, from: data)

                    guard let token = body.accessToken else {
                        print("[OAuth2Service] ❌ No access token in response")
                        completion(.failure(AuthServiceError.noAccessToken))
                        return
                    }

                    self.authToken = token
                    print("[OAuth2Service] ✅ Token saved")
                    completion(.success(token))

                } catch {
                    print("[OAuth2Service] ❌ Decode error: \(error)")
                    completion(.failure(error))
                }
            }
        }

        self.task = task
        task.resume()
    }

    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard let url = URL(string: Constants.unsplashTokenURLString) else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let params: [String: String] = [
            "client_id": Constants.accessKey,
            "client_secret": Constants.secretKey,
            "redirect_uri": Constants.redirectURI,
            "code": code,
            "grant_type": "authorization_code"
        ]

        let body = params
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")

        request.httpBody = body.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded",
                         forHTTPHeaderField: "Content-Type")

        return request
    }
}
