import XCTest
@testable import ImageFeed

final class testDidSelectRowCallsPresenter: XCTestCase {
    
    func testDidSelectRowCallsPresenter() {
        // given
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let sut = storyboard.instantiateViewController(
            withIdentifier: "ImagesListViewController"
        ) as! ImagesListViewController

        let presenter = ImagesListPresenterSpy()
        sut.configure(presenter)
        
        _ = sut.view
        
        guard let tableView = sut.view.subviews.compactMap({ $0 as? UITableView }).first else {
            XCTFail("UITableView не найден среди subviews")
            return
        }
        
        let indexPath = IndexPath(row: 0, section: 0)

        // when
        sut.tableView(tableView, didSelectRowAt: indexPath)

        // then
        XCTAssertEqual(presenter.didSelectRowIndex, 0)
    }
}
