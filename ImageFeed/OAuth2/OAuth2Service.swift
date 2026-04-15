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

    private init() { }

    func fetchOAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)
        guard lastCode != code else {
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }

        task?.cancel()
        lastCode = code
        guard let request = makeOAuthTokenRequest(code: code) else {
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }

        let task = urlSession.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error {
                    completion(.failure(error))
                    self.resetTask()
                    return
                }

                guard let data = data else {
                    completion(.failure(AuthServiceError.invalidRequest))
                    self.resetTask()
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let body = try decoder.decode(OAuthTokenResponseBody.self, from: data)

                    guard let accessToken = body.accessToken else {
                        completion(.failure(AuthServiceError.noAccessToken))
                        self.resetTask()
                        return
                    }

                    self.authToken = accessToken
                    completion(.success(accessToken))
                    self.resetTask()
                } catch {
                    completion(.failure(error))
                    self.resetTask()
                }
            }
        }
        self.task = task
        task.resume()
    }

    private func resetTask() {
        task = nil
        lastCode = nil
    }
  
    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard let url = URL(string: Constants.unsplashTokenURLString) else {
            print("Failed to create URL")
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

        let bodyString = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        return request
    }
}
