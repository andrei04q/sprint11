import Foundation

enum NetworkError: Error {
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case urlSessionError
    case invalidRequest
    case decodingError(Error)
    case urlCreationError
    case invalidResponse
    case invalidToken
}

extension URLSession {

    func data(
        for request: URLRequest,
        completion: @escaping (Result<Data, Error>) -> Void
    ) -> URLSessionTask {

        let fulfillCompletionOnTheMainThread: (Result<Data, Error>) -> Void = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }

        let task = dataTask(with: request) { data, response, error in

            if let data,
               let response = response as? HTTPURLResponse {

                let statusCode = response.statusCode

                if 200 ..< 300 ~= statusCode {

                    fulfillCompletionOnTheMainThread(.success(data))

                } else {

                    let error = NetworkError.httpStatusCode(statusCode)
                    print("[URLSession] failure: \(error)")
                    fulfillCompletionOnTheMainThread(.failure(error))
                }

            } else if let error {

                let wrappedError = NetworkError.urlRequestError(error)
                print("[URLSession] failure: \(wrappedError)")
                fulfillCompletionOnTheMainThread(.failure(wrappedError))

            } else {

                let error = NetworkError.urlSessionError
                print("[URLSession] failure: \(error)")
                fulfillCompletionOnTheMainThread(.failure(error))
            }
        }

        task.resume()
        return task
    }
}

// MARK: - Decodable task

extension URLSession {

    func objectTask<T: Decodable>(
        for request: URLRequest,
        completion: @escaping (Result<T, Error>) -> Void
    ) -> URLSessionTask {

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let task = data(for: request) { (result: Result<Data, Error>) in

            switch result {

            case let .success(data):

                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Полученные данные: \(jsonString)")
                }

                do {
                    let decodedObject = try decoder.decode(T.self, from: data)
                    completion(.success(decodedObject))
                } catch {

                    if let decodingError = error as? DecodingError {
                        print("Ошибка декодирования: \(decodingError), Данные: \(String(data: data, encoding: .utf8) ?? "")")
                    } else {
                        print("Ошибка декодирования: \(error.localizedDescription), Данные: \(String(data: data, encoding: .utf8) ?? "")")
                    }

                    completion(.failure(error))
                }

            case let .failure(error):

                print("Ошибка запроса: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }

        return task
    }
}
