import UIKit
import Kingfisher

final class ImagesListCell: UITableViewCell {
    static let reuseIdentifier = "ImagesListCell"
    
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var likeActiveButton: UIButton!
    
    weak var delegate: ImagesListCellDelegate?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cellImage.kf.cancelDownloadTask()
        cellImage.image = nil
        cellImage.kf.indicatorType = .none
    }
    
    @IBAction private func likeActiveButtonClicked(_ sender: UIButton) {
        print("🔥 LIKE BUTTON TAPED!")
        delegate?.photosListCellDidTapLike(self)
    }
    
    func setIsLiked(_ isLiked: Bool) {
        let imageName = isLiked ? "likeActiveButton" : "likeUnaktiveButton"
        let image = UIImage(named: imageName)
        print("🔥 \(imageName): \(image != nil ? "✅ OK" : "❌ NOT FOUND")")
        
        likeActiveButton.setImage(image, for: .normal)
        likeActiveButton.accessibilityIdentifier = "like button"
        likeActiveButton.isEnabled = true
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        likeActiveButton.accessibilityIdentifier = "like button"
    }
}
