import XCTest
@testable import ImageFeed

final class testCodeFromURL: XCTestCase {

    func testCodeFromURL() {
        // given
        let configuration = AuthConfiguration.standard
        let authHelper = AuthHelper(configuration: configuration)

        var components = URLComponents(string: "https://unsplash.com/oauth/authorize/native")
        components?.queryItems = [
            URLQueryItem(name: "code", value: "test code")
        ]
        let url = components?.url
        XCTAssertNotNil(url)

        // when
        let code = authHelper.code(from: url!)

        // then
        XCTAssertEqual(code, "test code")
    }
}
