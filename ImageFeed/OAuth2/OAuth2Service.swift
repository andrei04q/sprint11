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
    private var lastCode: String?

    private(set) var authToken: String? {
        get { dataStorage.token }
        set { dataStorage.token = newValue }
    }

    private init() {}

    func fetchOAuthToken(_ code: String,
                         completion: @escaping (Result<String, Error>) -> Void) {

        assert(Thread.isMainThread)

        if lastCode == code, task != nil {
            print("[OAuth2Service] failure: request already in progress for same code")
            return
        }

        task?.cancel()
        lastCode = code

        guard let request = makeOAuthTokenRequest(code: code) else {
            lastCode = nil
            print("[OAuth2Service] failure: invalid request")
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }

        let task = urlSession.dataTask(with: request) { [weak self] data, _, error in

            DispatchQueue.main.async {
                guard let self else { return }

                defer {
                    self.task = nil
                    self.lastCode = nil
                }

                if let error {
                    print("[OAuth2Service] failure: \(error)")
                    completion(.failure(error))
                    return
                }

                guard let data else {
                    print("[OAuth2Service] failure: empty response")
                    completion(.failure(AuthServiceError.invalidRequest))
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase

                    let body = try decoder.decode(OAuthTokenResponseBody.self, from: data)

                    guard let token = body.accessToken else {
                        print("[OAuth2Service] failure: no access token")
                        completion(.failure(AuthServiceError.noAccessToken))
                        return
                    }

                    self.authToken = token
                    print("[OAuth2Service] success")
                    completion(.success(token))

                } catch {
                    print("[OAuth2Service] failure: \(error)")
                    completion(.failure(error))
                }
            }
        }

        self.task = task
        task.resume()
    }

    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard let url = URL(string: Constants.unsplashTokenURLString) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let params: [String: String] = [
            "client_id": Constants.accessKey,
            "client_secret": Constants.secretKey,
            "redirect_uri": Constants.redirectURI,
            "code": code,
            "grant_type": "authorization_code"
        ]

        request.httpBody = params
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        request.setValue("application/x-www-form-urlencoded",
                         forHTTPHeaderField: "Content-Type")

        return request
    }
}
