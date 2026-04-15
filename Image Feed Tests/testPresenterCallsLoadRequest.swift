import XCTest
@testable import ImageFeed

final class testPresenterCallsLoadRequest: XCTestCase {
    
    func testPresenterCallsLoadRequest() {
        // given
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)
        let view = WebViewViewControllerSpy()
        view.presenter = presenter
        presenter.view = view
        
        // when
        presenter.viewDidLoad()
        
        // then
        XCTAssertTrue(view.loadRequestCalled, "Presenter должен вызвать load(request:) у view")
        XCTAssertNotNil(view.lastRequest, "Presenter должен передать непустой URLRequest в view")
    }
}
