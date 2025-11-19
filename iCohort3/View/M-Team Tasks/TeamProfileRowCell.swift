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
        


        [img1, img2, img3].forEach { img in
            img?.layer.cornerRadius = 30
            img?.clipsToBounds = true
            img?.contentMode = .scaleAspectFill
        }
    }

    func configureProfiles(images: [UIImage], names: [String]) {

      

        let imageViews = [img1, img2, img3]
        let labels = [name1, name2, name3]

        for i in 0..<3 {
            imageViews[i]?.image = (i < images.count) ? images[i] : UIImage(named: "Student")
            labels[i]?.text = (i < names.count) ? names[i] : "Member \(i+1)"
        }
    }

}

