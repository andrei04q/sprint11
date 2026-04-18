import Foundation

final class ImagesListService {

    static let shared = ImagesListService()
    static let didChangeNotification = Notification.Name("ImagesListServiceDidChange")

    private let photosURL = "https://api.unsplash.com/photos"
    private(set) var photos: [Photo] = []

    private var lastLoadedPage = 0
    private let perPage = 10

    private let urlSession = URLSession(configuration: .default)
    private var fetchPhotosTask: URLSessionTask?

    func fetchPhotosNextPage() {
        assert(Thread.isMainThread)

        guard fetchPhotosTask == nil else {
            print("[ImagesListService] failure: request already running")
            return
        }

        guard OAuth2TokenStorage.shared.token != nil else {
            print("[ImagesListService] failure: unauthorized")
            return
        }

        lastLoadedPage += 1
        let nextPage = lastLoadedPage

        guard var components = URLComponents(string: photosURL) else {
            print("[ImagesListService] failure: invalid url")
            return
        }

        components.queryItems = [
            URLQueryItem(name: "page", value: "\(nextPage)"),
            URLQueryItem(name: "per_page", value: "\(perPage)")
        ]

        guard let url = components.url else {
            print("[ImagesListService] failure: invalid url components")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        request.setValue("Client-ID \(Constants.accessKey)",
                         forHTTPHeaderField: "Authorization")

        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in

            DispatchQueue.main.async {
                guard let self else { return }
                self.fetchPhotosTask = nil

                if let error {
                    print("[ImagesListService] failure: \(error)")
                    return
                }

                guard let http = response as? HTTPURLResponse else {
                    print("[ImagesListService] failure: invalid response")
                    return
                }

                guard http.statusCode == 200 else {
                    print("[ImagesListService] failure: http \(http.statusCode)")
                    return
                }

                guard let data else {
                    print("[ImagesListService] failure: empty data")
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase

                    let results = try decoder.decode([PhotoResult].self, from: data)
                    let newPhotos = results.map { Photo(from: $0) }

                    self.photos.append(contentsOf: newPhotos)

                    NotificationCenter.default.post(
                        name: ImagesListService.didChangeNotification,
                        object: nil
                    )

                    print("[ImagesListService] success: loaded \(newPhotos.count) photos")

                } catch {
                    print("[ImagesListService] failure: \(error)")
                }
            }
        }

        fetchPhotosTask = task
        task.resume()
    }

    func changeLike(photoId: String,
                    isLike: Bool,
                    _ completion: @escaping (Result<Void, Error>) -> Void) {

        let urlString = "https://api.unsplash.com/photos/\(photoId)/like"

        guard let url = URL(string: urlString) else {
            print("[ImagesListService] failure: invalid url")
            completion(.failure(URLError(.badURL)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = isLike ? HTTPMethod.post.rawValue : HTTPMethod.delete.rawValue

        guard let token = OAuth2TokenStorage.shared.token else {
            print("[ImagesListService] failure: missing token")
            completion(.failure(URLError(.userAuthenticationRequired)))
            return
        }

        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        urlSession.dataTask(with: request) { [weak self] _, response, error in

            DispatchQueue.main.async {

                if let error {
                    print("[ImagesListService] failure: \(error)")
                    completion(.failure(error))
                    return
                }

                guard let http = response as? HTTPURLResponse,
                      (200...299).contains(http.statusCode) else {

                    let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                    print("[ImagesListService] failure: http \(code)")
                    completion(.failure(URLError(.badServerResponse)))
                    return
                }

                if let self,
                   let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                    self.photos[index].isLiked.toggle()
                }

                NotificationCenter.default.post(
                    name: ImagesListService.didChangeNotification,
                    object: nil
                )

                print("[ImagesListService] success")
                completion(.success(()))
            }

        }.resume()
    }

    func reset() {
        photos.removeAll()
        lastLoadedPage = 0
        fetchPhotosTask?.cancel()
        fetchPhotosTask = nil

        print("[ImagesListService] success: reset")
    }
}
