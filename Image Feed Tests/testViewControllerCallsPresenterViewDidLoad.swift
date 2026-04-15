import XCTest
@testable import ImageFeed

final class ProfileViewControllerTests: XCTestCase {

    func testProfileVCCallsPresenterViewDidLoad() {
        // given
        let sut = ProfileViewController()
        let presenter = ProfilePresenterSpy()
        sut.configure(presenter)

        // when
        _ = sut.view

        // then
        XCTAssertTrue(presenter.viewDidLoadCalled)
    }
}

