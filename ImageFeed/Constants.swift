import UIKit

// MARK: - Progress
enum Progress {
    static let completedValue: Double = 1.0
    static let hideThreshold: Double = 0.0001
}

// MARK: - Alerts
enum Alerts {
    static let errorTitle = "Что-то пошло не так("
    static let authErrorPrefix = "Не удалось войти в систему. Ошибка: "
    static let okButtonTitle = "OK"
}

// MARK: - HTTPMethod
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

//  MARK: - WebViewConstants
enum WebViewConstants {
    static let unsplashAuthorizeURLString = "https://unsplash.com/oauth/authorize"
    static let clientIDQueryName = "client_id"
    static let redirectURIQueryName = "redirect_uri"
    static let responseTypeQueryName = "response_type"
    static let scopeQueryName = "scope"
    static let responseTypeCode = "code"
    static let authorizeNativePath = "/oauth/authorize/native"
}
