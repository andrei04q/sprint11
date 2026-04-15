import UIKit

final class ImagesListPresenter: ImagesListPresenterProtocol {
    weak var view: ImagesListViewControllerProtocol?
    
    private let imagesListService: ImagesListService
    private let tokenStorage: OAuth2TokenStorage
    private var photos: [Photo] = []
    private var photosObserver: NSObjectProtocol?
    private var likeRequestsInProgress = Set<String>()
    
    var photosCount: Int {
        photos.count
    }
    
    init(
        imagesListService: ImagesListService = .shared,
        tokenStorage: OAuth2TokenStorage = .shared
    ) {
        self.imagesListService = imagesListService
        self.tokenStorage = tokenStorage
    }
    
    func viewDidLoad() {
        guard tokenStorage.token != nil else {
            print("❌ ImagesListPresenter: Требуется авторизация")
            return
        }
        
        photos = imagesListService.photos
        view?.updateTableView()
        
        photosObserver = NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handlePhotosUpdated()
        }
        
        imagesListService.fetchPhotosNextPage()
    }
    
    private func handlePhotosUpdated() {
        let oldCount = photos.count
        let newPhotos = imagesListService.photos
        photos = newPhotos
        
        if newPhotos.count > oldCount {
            let startIndex = oldCount
            let endIndex = newPhotos.count - 1
            let indexPaths = (startIndex...endIndex).map { IndexPath(row: $0, section: 0) }
            view?.insertRows(at: indexPaths)
        } else {
            view?.updateTableView()
        }
    }
    
    func photo(at index: Int) -> Photo {
        photos[index]
    }
    
    func didTapLike(at index: Int, cell: ImagesListCell) {
        let photo = photos[index]
        
        if likeRequestsInProgress.contains(photo.id) {
            print("🔥 Запрос лайка уже выполняется для photo.id = \(photo.id)")
            return
        }
        
        let newIsLiked = !photo.isLiked
        cell.setIsLiked(newIsLiked)
        
        likeRequestsInProgress.insert(photo.id)
        
        imagesListService.changeLike(
            photoId: photo.id,
            isLike: newIsLiked
        ) { [weak self] result in
            guard let self else { return }
            
            self.likeRequestsInProgress.remove(photo.id)
            
            switch result {
            case .success:
                print("🔥 changeLike SUCCESS")
                self.photos[index].isLiked = newIsLiked
            case .failure(let error):
                print("🔥 changeLike FAILURE: \(error)")
                cell.setIsLiked(photo.isLiked)
            }
        }
    }
    
    func didSelectRow(at index: Int) {
        let photo = photos[index]
        
        if likeRequestsInProgress.contains(photo.id) {
            print("🙅‍♂ Tap по ячейке заблокирован: идёт запрос лайка для \(photo.id)")
            return
        }
    }
    
    func willDisplayRow(at index: Int) {
        if index == photos.count - 1 {
            imagesListService.fetchPhotosNextPage()
        }
    }
}
