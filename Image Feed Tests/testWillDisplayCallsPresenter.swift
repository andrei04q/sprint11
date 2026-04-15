import XCTest
@testable import ImageFeed

final class testWillDisplayCallsPresenter: XCTestCase {

    func testWillDisplayCallsPresenter() {
        // given
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let sut = storyboard.instantiateViewController(
            withIdentifier: "ImagesListViewController"
        ) as! ImagesListViewController

        let presenter = ImagesListPresenterSpy()
        sut.configure(presenter)
        _ = sut.view

        let tableView = sut.view.subviews.compactMap { $0 as? UITableView }.first!
        let indexPath = IndexPath(row: 0, section: 0)
        let cell = UITableViewCell()

        // when
        sut.tableView(tableView, willDisplay: cell, forRowAt: indexPath)

        // then
        XCTAssertEqual(presenter.willDisplayRowIndex, 0)
    }
}
