import UIKit

class TeamProfileRowCell: UICollectionViewCell {

    @IBOutlet weak var img1: UIImageView!
    @IBOutlet weak var img2: UIImageView!
    @IBOutlet weak var img3: UIImageView!

    @IBOutlet weak var name1: UILabel!
    @IBOutlet weak var name2: UILabel!
    @IBOutlet weak var name3: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        // Style all profile images
        [img1, img2, img3].forEach { img in
            img?.layer.cornerRadius = 35
            img?.clipsToBounds = true
            img?.contentMode = .scaleAspectFill
            img?.backgroundColor = UIColor(white: 0.95, alpha: 1)
        }
        
        // Style all name labels
        [name1, name2, name3].forEach { label in
            label?.font = .systemFont(ofSize: 14, weight: .medium)
            label?.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
            label?.textAlignment = .center
        }
    }

    func configureProfiles(images: [UIImage], names: [String], teamNo: Int) {

        let imageViews = [img1, img2, img3]
        let labels = [name1, name2, name3]

        // ✅ Clean names by removing "Team X - " prefix if present
        let cleanedNames: [String] = names.map { raw in
            // Remove pattern "Team 9 - " or similar
            let pattern = "Team \\d+ - "
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(raw.startIndex..., in: raw)
                let cleaned = regex.stringByReplacingMatches(in: raw, options: [], range: range, withTemplate: "")
                return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return raw.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Configure up to 3 members
        for i in 0..<3 {
            if i < cleanedNames.count {
                // Set image (use provided image or default)
                imageViews[i]?.image = (i < images.count) ? images[i] : UIImage(named: "Student")
                
                // Set name
                labels[i]?.text = cleanedNames[i]
                
                // Show the views
                imageViews[i]?.isHidden = false
                labels[i]?.isHidden = false
            } else {
                // Hide extra slots if team has fewer than 3 members
                imageViews[i]?.isHidden = true
                labels[i]?.isHidden = true
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset all to visible with defaults
        [img1, img2, img3].forEach { img in
            img?.image = UIImage(named: "Student")
            img?.isHidden = false
        }
        
        [name1, name2, name3].forEach { label in
            label?.text = ""
            label?.isHidden = false
        }
    }
}
