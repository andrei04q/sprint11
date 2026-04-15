import XCTest
@testable import ImageFeed

final class ImagesListViewControllerSpy: ImagesListViewControllerProtocol {
    private(set) var updateTableViewCalled = false
    private(set) var insertedIndexPaths: [IndexPath] = []
    private(set) var updatedIndexPath: IndexPath?
    private(set) var updatedIsLiked: Bool?

    func updateTableView() {
        updateTableViewCalled = true
    }

    func insertRows(at indexPaths: [IndexPath]) {
        insertedIndexPaths = indexPaths
    }

    func updateCell(at indexPath: IndexPath, isLiked: Bool) {
        updatedIndexPath = indexPath
        updatedIsLiked = isLiked
    }
}
