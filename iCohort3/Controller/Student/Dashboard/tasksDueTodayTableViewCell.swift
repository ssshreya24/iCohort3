import UIKit

class tasksDueTodayTableViewCell: UITableViewCell {

    @IBOutlet weak var chevronRight: UIButton!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var assignedTo: UILabel!
    @IBOutlet weak var taskDescription: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var cardView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Set cell background to clear
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        setupCardStyle()
        setupProfileImage()
        
        print("✅ Cell awakeFromNib called")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update profile image corner radius after layout
        profileImage.layer.cornerRadius = profileImage.frame.height / 2
    }

    private func setupCardStyle() {
        cardView.layer.cornerRadius = 16
        cardView.layer.masksToBounds = false
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.15
        cardView.layer.shadowOffset = CGSize(width: 0, height: 3)
        cardView.layer.shadowRadius = 6
        cardView.backgroundColor = .white
    }

    private func setupProfileImage() {
        profileImage.layer.cornerRadius = profileImage.frame.height / 2
        profileImage.clipsToBounds = true
        profileImage.contentMode = .scaleAspectFill
        profileImage.backgroundColor = .systemGray5 // Fallback color
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset cell content
        name.text = nil
        taskDescription.text = nil
        assignedTo.text = nil
        profileImage.image = nil
    }
}
