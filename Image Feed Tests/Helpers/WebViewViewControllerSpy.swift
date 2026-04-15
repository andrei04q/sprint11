import XCTest
@testable import ImageFeed
import WebKit

final class WebViewViewControllerSpy: WebViewViewControllerProtocol {
    var presenter: WebViewPresenterProtocol?
    
    private(set) var loadRequestCalled = false
    private(set) var lastRequest: URLRequest?
    
    func setProgressValue(_ value: Float) { }
    
    func setProgressHidden(_ isHidden: Bool) { }
    
    func load(request: URLRequest) {
        loadRequestCalled = true
        lastRequest = request
    }
}
