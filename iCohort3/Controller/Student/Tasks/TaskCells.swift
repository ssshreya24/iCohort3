//
//  TaskCells.swift
//  iCohort3
//
//  Created by user@51 on 24/02/26.
//

import UIKit

// MARK: - Shared date formatter helper

private extension String {
    /// Converts an ISO-8601 string to "dd MMM yyyy". Returns self unchanged on failure.
    var prettyDate: String {
        let f1 = ISO8601DateFormatter()
        f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let f2 = ISO8601DateFormatter()
        if let d = f1.date(from: self) ?? f2.date(from: self) {
            let df = DateFormatter()
            df.dateFormat = "dd MMM yyyy"
            return df.string(from: d)
        }
        // Already formatted (e.g. "27 Feb 2026") — return as-is
        return self
    }
}

// MARK: - TaskCollectionViewCell (Assigned / blue)

class TaskCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var circleButton:     UIButton!
    @IBOutlet weak var titleLabel:       UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var assignedLabel:    UILabel!
    @IBOutlet weak var dueDateLabel:     UILabel!
    @IBOutlet weak var nameLabel:        UILabel!
    @IBOutlet weak var separatorView:    UIView!
    @IBOutlet weak var cardView:         UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    private func setupUI() {
        styleCard(cardView)
        styleProfileImage(profileImageView)
        separatorView.backgroundColor = .systemGray5
        styleLabels(assigned: assignedLabel, name: nameLabel,
                    title: titleLabel, desc: descriptionLabel)
    }

    /// - Parameter dueDate: ISO-8601 string OR already-formatted "dd MMM yyyy" string
    func configure(title: String, desc: String, image: UIImage?, name: String, dueDate: String) {
        titleLabel.text       = title
        descriptionLabel.text = desc
        profileImageView.image = image
        assignedLabel.text    = "Assigned To"
        nameLabel.text        = name
        dueDateLabel.text     = "Due Date: \(dueDate.prettyDate)"
    }
}

// MARK: - InProgressCollectionViewCell (Ongoing / blue)

class InProgressCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var circleButton:     UIButton!
    @IBOutlet weak var titleLabel:       UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var assignedLabel:    UILabel!
    @IBOutlet weak var dueDateLabel:     UILabel!
    @IBOutlet weak var nameLabel:        UILabel!
    @IBOutlet weak var separatorView:    UIView!
    @IBOutlet weak var cardView:         UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    private func setupUI() {
        styleCard(cardView)
        styleProfileImage(profileImageView)
        separatorView.backgroundColor = .systemGray5
        styleLabels(assigned: assignedLabel, name: nameLabel,
                    title: titleLabel, desc: descriptionLabel)
    }

    func configure(title: String, desc: String, image: UIImage?, name: String, dueDate: String) {
        titleLabel.text        = title
        descriptionLabel.text  = desc
        profileImageView.image = image
        assignedLabel.text     = "Assigned To"
        nameLabel.text         = name
        dueDateLabel.text      = "Due Date: \(dueDate.prettyDate)"
    }
}

// MARK: - ForReviewCollectionViewCell (yellow)

class ForReviewCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var circleButton:     UIButton!
    @IBOutlet weak var titleLabel:       UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var assignedLabel:    UILabel!
    @IBOutlet weak var dueDateLabel:     UILabel!
    @IBOutlet weak var nameLabel:        UILabel!
    @IBOutlet weak var separatorView:    UIView!
    @IBOutlet weak var cardView:         UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        circleButton.backgroundColor     = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
        circleButton.layer.cornerRadius  = circleButton.frame.height / 2
        circleButton.clipsToBounds       = true
        circleButton.isUserInteractionEnabled = false
    }

    private func setupUI() {
        styleCard(cardView)
        styleProfileImage(profileImageView)
        separatorView.backgroundColor = .systemGray5
        styleLabels(assigned: assignedLabel, name: nameLabel,
                    title: titleLabel, desc: descriptionLabel)
    }

    func configure(title: String, desc: String, image: UIImage?, name: String, dueDate: String) {
        titleLabel.text        = title
        descriptionLabel.text  = desc
        profileImageView.image = image
        assignedLabel.text     = "Assigned To"
        nameLabel.text         = name
        dueDateLabel.text      = "Due Date: \(dueDate.prettyDate)"
    }
}

// MARK: - PreparedCollectionViewCell

class PreparedCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var circleButton:     UIButton!
    @IBOutlet weak var titleLabel:       UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var assignedLabel:    UILabel!
    @IBOutlet weak var dueDateLabel:     UILabel!
    @IBOutlet weak var nameLabel:        UILabel!
    @IBOutlet weak var separatorView:    UIView!
    @IBOutlet weak var cardView:         UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    private func setupUI() {
        styleCard(cardView)
        styleProfileImage(profileImageView)
        separatorView.backgroundColor = .systemGray5
        styleLabels(assigned: assignedLabel, name: nameLabel,
                    title: titleLabel, desc: descriptionLabel)
    }

    func configure(title: String, desc: String, image: UIImage?, name: String, dueDate: String) {
        titleLabel.text        = title
        descriptionLabel.text  = desc
        profileImageView.image = image
        assignedLabel.text     = "Assigned To"
        nameLabel.text         = name
        dueDateLabel.text      = "Due Date: \(dueDate.prettyDate)"
    }
}

// MARK: - ApprovedCollectionViewCell (green, with remark)

class ApprovedCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var circleButton:      UIButton!
    @IBOutlet weak var titleLabel:        UILabel!
    @IBOutlet weak var descriptionLabel:  UILabel!
    @IBOutlet weak var remarkTitleLabel:  UILabel!
    @IBOutlet weak var remarkDescLabel:   UILabel!
    @IBOutlet weak var profileImageView:  UIImageView!
    @IBOutlet weak var assignedLabel:     UILabel!
    @IBOutlet weak var dueDateLabel:      UILabel!
    @IBOutlet weak var nameLabel:         UILabel!
    @IBOutlet weak var separatorView:     UIView!
    @IBOutlet weak var cardView:          UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    private func setupUI() {
        styleCard(cardView)
        styleProfileImage(profileImageView)
        separatorView.backgroundColor = .systemGray5
        styleLabels(assigned: assignedLabel, name: nameLabel,
                    title: titleLabel, desc: descriptionLabel)

        circleButton.layer.cornerRadius  = circleButton.frame.height / 2
        circleButton.backgroundColor     = UIColor(red: 0.30, green: 0.75, blue: 0.39, alpha: 1.0)
        circleButton.isUserInteractionEnabled = true

        remarkDescLabel.numberOfLines = 0
        remarkDescLabel.lineBreakMode = .byWordWrapping
    }

    func configure(title: String,
                   desc: String,
                   remark: String?,
                   image: UIImage?,
                   name: String,
                   dueDate: String) {
        titleLabel.text        = title
        descriptionLabel.text  = desc
        profileImageView.image = image
        assignedLabel.text     = "Assigned To"
        nameLabel.text         = name
        dueDateLabel.text      = "Due Date: \(dueDate.prettyDate)"

        let hasRemark = remark.map { !$0.isEmpty } ?? false
        remarkTitleLabel.isHidden = !hasRemark
        remarkDescLabel.isHidden  = !hasRemark
        remarkDescLabel.text      = remark
    }
}

// MARK: - CompletedCollectionViewCell (green)

class CompletedCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var circleButton:     UIButton!
    @IBOutlet weak var titleLabel:       UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var assignedLabel:    UILabel!
    @IBOutlet weak var dueDateLabel:     UILabel!
    @IBOutlet weak var nameLabel:        UILabel!
    @IBOutlet weak var separatorView:    UIView!
    @IBOutlet weak var cardView:         UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    private func setupUI() {
        styleCard(cardView)
        styleProfileImage(profileImageView)
        separatorView.backgroundColor = .systemGray5
        styleLabels(assigned: assignedLabel, name: nameLabel,
                    title: titleLabel, desc: descriptionLabel)
    }

    func configure(title: String, desc: String, image: UIImage?, name: String, dueDate: String) {
        titleLabel.text        = title
        descriptionLabel.text  = desc
        profileImageView.image = image
        assignedLabel.text     = "Assigned To"
        nameLabel.text         = name
        dueDateLabel.text      = "Due Date: \(dueDate.prettyDate)"
    }
}

// MARK: - RejectedCollectionViewCell (red, with remark)

class RejectedCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var circleButton:      UIButton!
    @IBOutlet weak var titleLabel:        UILabel!
    @IBOutlet weak var descriptionLabel:  UILabel!
    @IBOutlet weak var remarkTitleLabel:  UILabel!
    @IBOutlet weak var remarkDescLabel:   UILabel!
    @IBOutlet weak var profileImageView:  UIImageView!
    @IBOutlet weak var assignedLabel:     UILabel!
    @IBOutlet weak var dueDateLabel:      UILabel!
    @IBOutlet weak var nameLabel:         UILabel!
    @IBOutlet weak var separatorView:     UIView!
    @IBOutlet weak var cardView:          UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    private func setupUI() {
        styleCard(cardView)
        styleProfileImage(profileImageView)
        separatorView.backgroundColor = .systemGray5
        styleLabels(assigned: assignedLabel, name: nameLabel,
                    title: titleLabel, desc: descriptionLabel)

        circleButton.layer.cornerRadius  = circleButton.frame.height / 2
        circleButton.backgroundColor     = UIColor.systemRed
        circleButton.isUserInteractionEnabled = false

        remarkDescLabel.numberOfLines = 0
        remarkDescLabel.lineBreakMode = .byWordWrapping
    }

    func configure(title: String,
                   desc: String,
                   remark: String?,
                   image: UIImage?,
                   name: String,
                   dueDate: String) {
        titleLabel.text        = title
        descriptionLabel.text  = desc
        profileImageView.image = image
        assignedLabel.text     = "Assigned To"
        nameLabel.text         = name
        dueDateLabel.text      = "Due Date: \(dueDate.prettyDate)"

        let hasRemark = remark.map { !$0.isEmpty } ?? false
        remarkTitleLabel.isHidden = !hasRemark
        remarkDescLabel.isHidden  = !hasRemark
        remarkDescLabel.text      = remark
    }
}

// MARK: - Shared styling helpers (private, file-scoped)

private func styleCard(_ view: UIView) {
    view.layer.cornerRadius  = 15
    view.layer.masksToBounds = false
    view.backgroundColor     = .white
    view.layer.shadowColor   = UIColor.black.cgColor
    view.layer.shadowOpacity = 0.1
    view.layer.shadowOffset  = CGSize(width: 0, height: 3)
    view.layer.shadowRadius  = 6
}

private func styleProfileImage(_ iv: UIImageView) {
    iv.layer.cornerRadius = iv.frame.width / 2
    iv.clipsToBounds      = true
}

private func styleLabels(assigned: UILabel, name: UILabel,
                         title: UILabel, desc: UILabel) {
    assigned.textColor = .systemGray3
    assigned.font      = UIFont.systemFont(ofSize: 13)

    name.font      = UIFont.systemFont(ofSize: 15, weight: .medium)
    name.textColor = .label

    title.font = UIFont.systemFont(ofSize: 16, weight: .semibold)

    desc.font      = UIFont.systemFont(ofSize: 14)
    desc.textColor = .darkGray
}
