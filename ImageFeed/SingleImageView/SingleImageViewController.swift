import UIKit
import Kingfisher

final class SingleImageViewController: UIViewController {

    var image: UIImage? {
        didSet {
            guard isViewLoaded, let image else { return }
            imageView.image = image
            rescaleAndCenterImageInScrollView(image: image)
        }
    }

    var imageURL: String? {
        didSet {
            if isViewLoaded {
                loadImage()
            }
        }
    }

    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        backButton.accessibilityIdentifier = "backButton"
        
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 3.0

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        if let image {
            imageView.image = image
            rescaleAndCenterImageInScrollView(image: image)
        } else {
            loadImage()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateImageViewFrame()
    }

    // MARK: - Actions
    @IBOutlet private weak var backButton: UIButton!

    @IBAction private func didTapBackButton() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction private func didTapShareButton(_ sender: UIButton) {
        guard let image else { return }
        let share = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        present(share, animated: true, completion: nil)
    }

    // MARK: - Image loading

    private func loadImage() {
        guard let imageURL,
              let url = URL(string: imageURL) else { return }

        UIBlockingProgressHUD.show()
        imageView.kf.indicatorType = .none
        imageView.kf.setImage(with: url) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            guard let self = self else { return }

            switch result {
            case .success(let value):
                let image = value.image
                self.image = image
                self.imageView.image = image
                self.rescaleAndCenterImageInScrollView(image: image)

            case .failure:
                self.showError()
            }
        }
    }

    private func showError() {
        let alert = UIAlertController(
            title: "Что-то пошло не так",
            message: "Попробовать ещё раз?",
            preferredStyle: .alert
        )

        let cancelAction = UIAlertAction(title: "Не надо", style: .cancel, handler: nil)
        let retryAction = UIAlertAction(title: "Повторить", style: .default) { [weak self] _ in
            self?.loadImage()
        }

        alert.addAction(cancelAction)
        alert.addAction(retryAction)

        present(alert, animated: true)
    }

    // MARK: - ScrollView helpers

    private func rescaleAndCenterImageInScrollView(image: UIImage) {
        let visibleRect = view.frame
        let imageSize = image.size
        let hScale = visibleRect.width / imageSize.width
        let vScale = visibleRect.height / imageSize.height
        let scale = max(hScale, vScale)
        
        scrollView.minimumZoomScale = scale
        scrollView.maximumZoomScale = 3.0
        scrollView.zoomScale = scale

        updateImageViewFrame()
        centerImage()
    }
    
    private func updateImageViewFrame() {
        imageView.frame = CGRect(origin: .zero, size: scrollView.bounds.size)
        scrollView.contentSize = scrollView.bounds.size
    }

    private func centerImage() {
        let scrollViewSize = scrollView.bounds.size
        let imageViewSize = imageView.frame.size

        let horizontalInset = max(0, (scrollViewSize.width - imageViewSize.width) / 2)
        let verticalInset = max(0, (scrollViewSize.height - imageViewSize.height) / 2)

        scrollView.contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
        )
    }

    private func updateScrollViewInsets() {
        centerImage()
    }
}

extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateScrollViewInsets()
    }
}
