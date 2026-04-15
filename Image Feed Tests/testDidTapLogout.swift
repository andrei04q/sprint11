import XCTest
@testable import ImageFeed

final class testDidTapLogout: XCTestCase {
    
    func testViewControllerCallsPresenterDidTapLogout() {
        // given
        let sut = ProfileViewController()
        let presenter = ProfilePresenterSpy()
        sut.configure(presenter)

        // when
        sut.perform(#selector(ProfileViewController.didTaplogoutProfileButton))

        // then
        XCTAssertTrue(presenter.didTapLogoutCalled)
    }
}
