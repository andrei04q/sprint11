import UIKit

extension DateFormatter {
    static let unsplashDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return formatter
    }()
}

struct PhotoResult: Codable {
    let id: String
    let createdAt: String?
    let width: Int
    let height: Int
    let description: String?
    let urls: UrlsResult
    let likedByUser: Bool?

}

struct UrlsResult: Codable {
    let full: String
    let regular: String
    let small: String
    let thumb: String
}

struct Photo {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let welcomeDescription: String?
    let thumbImageURL: String
    let largeImageURL: String
    let fullImageURL: String
    var isLiked: Bool
}

extension Photo {
    init(from result: PhotoResult) {
        self.id = result.id
        self.size = CGSize(width: result.width, height: result.height)
        print("🔥 RAW createdAt: '\(result.createdAt ?? "nil")'")
        self.createdAt = result.createdAt.flatMap {
            DateFormatter.unsplashDateFormatter.date(from: $0)
        }
        print("🔥 PARSED Date: \(self.createdAt?.description ?? "nil")")
        self.welcomeDescription = result.description
        self.thumbImageURL = result.urls.thumb
        self.largeImageURL = result.urls.regular
        self.fullImageURL = result.urls.full
        self.isLiked = result.likedByUser ?? false
    }
}
