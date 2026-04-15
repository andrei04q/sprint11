//
// ImagesListViewController.swift
// ImageFeed
//
// Created by Воробьева Юлия on 03.10.2025.
//

import UIKit
import Kingfisher

final class ImagesListViewController: UIViewController,
                                      ImagesListViewControllerProtocol,
                                      ImagesListCellDelegate {
    
    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    
    @IBOutlet private var tableView: UITableView!
    
    private var presenter: ImagesListPresenterProtocol!
    
    func configure(_ presenter: ImagesListPresenterProtocol) {
        self.presenter = presenter
        presenter.view = self
    }
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.prefetchDataSource = nil
        
        if self.presenter == nil {
            self.presenter = ImagesListPresenter()
        }
        self.presenter.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == showSingleImageSegueIdentifier,
              let viewController = segue.destination as? SingleImageViewController,
              let indexPath = sender as? IndexPath,
              indexPath.row < presenter.photosCount
        else {
            print("❌ prepare(for:sender:) — неверные данные!")
            return
        }
        
        let photo = presenter.photo(at: indexPath.row)
        guard URL(string: photo.fullImageURL) != nil
        else {
            print("❌ Нет URL для index: \(indexPath.row)")
            return
        }
        
        viewController.imageURL = photo.fullImageURL
    }
    
    // MARK: - ImagesListViewControllerProtocol
    func updateTableView() {
        tableView.reloadData()
    }
    
    func insertRows(at indexPaths: [IndexPath]) {
        tableView.performBatchUpdates {
            tableView.insertRows(at: indexPaths, with: .automatic)
        }
    }
    
    func updateCell(at indexPath: IndexPath, isLiked: Bool) {
        guard let cell = tableView.cellForRow(at: indexPath) as? ImagesListCell else { return }
        cell.setIsLiked(isLiked)
    }
    
    func photosListCellDidTapLike(_ cell: ImagesListCell) {
        print("🔥 CONTROLLER: Delegate сработал!")
        
        guard let indexPath = tableView.indexPath(for: cell) else {
            print("❌ Нет indexPath!")
            return
        }
        
        let photo = presenter.photo(at: indexPath.row)
        let newIsLiked = !photo.isLiked
        cell.setIsLiked(newIsLiked)
        
        ImagesListService.shared.changeLike(photoId: photo.id, isLike: newIsLiked) { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case .success:
                print("✅ API лайк сработал")
            case .failure(let error):
                print("❌ API лайк ошибка: \(error)")
                cell.setIsLiked(photo.isLiked)
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        presenter.photosCount
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ImagesListCell.reuseIdentifier,
            for: indexPath
        )
        
        guard let imageListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }
        
        configCell(for: imageListCell, with: indexPath)
        imageListCell.delegate = self
        
        return imageListCell
    }
}

// MARK: - Cell configuration
extension ImagesListViewController {
    func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        let photo = presenter.photo(at: indexPath.row)
        
        if let thumbURL = URL(string: photo.thumbImageURL) {
            cell.cellImage.kf.setImage(
                with: thumbURL,
                placeholder: UIImage(named: "photoPlaceholder")
            )
        } else {
            cell.cellImage.image = UIImage(named: "photoPlaceholder")
        }
        
        if let date = photo.createdAt {
            cell.dateLabel.text = dateFormatter.string(from: date)
        } else {
            cell.dateLabel.text = "Дата неизвестна"
        }
        
        cell.setIsLiked(photo.isLiked)
    }
}

// MARK: - UITableViewDelegate
extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard presenter != nil else {
            print("❌ PRESENTER NIL!")
            return
        }
        
        guard indexPath.row < presenter.photosCount else {
            print("❌ Неверный indexPath: \(indexPath.row)")
            return
        }
        
        presenter.didSelectRow(at: indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.row < presenter.photosCount else { return 44 }
        let photo = presenter.photo(at: indexPath.row)
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = tableView.bounds.width - imageInsets.left - imageInsets.right
        let width = max(photo.size.width, 1)
        let height = max(photo.size.height, 1)
        
        let scale = imageViewWidth / width
        let cellHeight = height * scale + imageInsets.top + imageInsets.bottom
        return max(cellHeight, 44)
    }
    
    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {
        presenter.willDisplayRow(at: indexPath.row)
    }
}
