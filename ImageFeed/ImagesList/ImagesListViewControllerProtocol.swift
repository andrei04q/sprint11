import UIKit

protocol ImagesListViewControllerProtocol: AnyObject {
    func updateTableView()
    func insertRows(at indexPaths: [IndexPath])
    func updateCell(at indexPath: IndexPath, isLiked: Bool)
}

protocol ImagesListPresenterProtocol: AnyObject {
    var view: ImagesListViewControllerProtocol? { get set }
    var photosCount: Int { get }
    func viewDidLoad()
    func photo(at index: Int) -> Photo
    func didTapLike(at index: Int, cell: ImagesListCell)
    func didSelectRow(at index: Int)
    func willDisplayRow(at index: Int)
}
