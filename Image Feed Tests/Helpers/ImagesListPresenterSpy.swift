import XCTest
@testable import ImageFeed

final class ImagesListPresenterSpy: ImagesListPresenterProtocol {
    weak var view: ImagesListViewControllerProtocol?

    private(set) var viewDidLoadCalled = false
    private(set) var didTapLikeIndex: Int?
    private(set) var didSelectRowIndex: Int?
    private(set) var willDisplayRowIndex: Int?

    var photosCount: Int = 1
    private let stubPhoto = Photo(
        id: "id",
        size: CGSize(width: 100, height: 200),
        createdAt: Date(),
        welcomeDescription: nil,
        thumbImageURL: "https://example.com/thumb", largeImageURL: "https://example.com/thumb",
        fullImageURL: "https://example.com/full",
        isLiked: false
    )

    func viewDidLoad() {
        viewDidLoadCalled = true
    }

    func photo(at index: Int) -> Photo {
        stubPhoto
    }

    func didTapLike(at index: Int, cell: ImagesListCell) {
        didTapLikeIndex = index
    }

    func didSelectRow(at index: Int) {
        didSelectRowIndex = index
    }

    func willDisplayRow(at index: Int) {
        willDisplayRowIndex = index
    }
}
