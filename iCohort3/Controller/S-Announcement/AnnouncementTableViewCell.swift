//
//  AnnouncementTableViewCell.swift
//  iCohort3
//

import UIKit

class AnnouncementCell: UITableViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var metaLabel: UILabel!
    @IBOutlet weak var attachmentButton: UIButton!
    
    // Closure to handle attachment tap
    var onAttachmentTapped: (([AttachmentType]) -> Void)?
    
    private var attachments: [AttachmentType] = []
    
    var customTagColor: UIColor?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        containerView.layer.cornerRadius = 14
        containerView.layer.masksToBounds = true

        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.06
        contentView.layer.shadowRadius = 6
        contentView.layer.shadowOffset = CGSize(width: 0, height: 3)
        contentView.layer.masksToBounds = false

        tagLabel.layer.masksToBounds = true
        tagLabel.layer.cornerRadius = 12
        tagLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        tagLabel.textColor = .white
        tagLabel.textAlignment = .center
        
        // Setup attachment button
        attachmentButton.addTarget(self, action: #selector(attachmentButtonTapped), for: .touchUpInside)
        setupAttachmentButton()
    }
    
    private func setupAttachmentButton() {
        attachmentButton.setTitleColor(.systemBlue, for: .normal)
        attachmentButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        
        // Set the paperclip icon
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let paperclipImage = UIImage(systemName: "paperclip", withConfiguration: config)
        attachmentButton.setImage(paperclipImage, for: .normal)
        attachmentButton.tintColor = .systemBlue
        
        // Position image to the left of text
        attachmentButton.semanticContentAttribute = .forceLeftToRight
    }

    func configure(with a: Announcement) {
        titleLabel.text = a.title
        bodyLabel.text = a.body
        
        if let t = a.tag {
            tagLabel.isHidden = false
            tagLabel.text = "\(t)    "
            tagLabel.textAlignment = .center

            // Use stored color from announcement if available
            if let storedColor = a.tagColor {
                tagLabel.backgroundColor = storedColor
            } else if let userColor = customTagColor {
                // Fallback to custom color
                tagLabel.backgroundColor = userColor
            } else {
                // Default colors based on tag type
                if t.lowercased().contains("event") {
                    tagLabel.backgroundColor = UIColor(red: 0.18, green: 0.78, blue: 0.42, alpha: 1)
                } else {
                    tagLabel.backgroundColor = UIColor(red: 0.95, green: 0.74, blue: 0.18, alpha: 1)
                }
            }

            // Auto-resize pill shape
            tagLabel.layoutIfNeeded()
            tagLabel.layer.cornerRadius = tagLabel.frame.height / 2
            tagLabel.clipsToBounds = true

        } else {
            tagLabel.isHidden = true
        }

        // Date format
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM • h:mm a"

        metaLabel.text = "\(formatter.string(from: a.createdAt)) • BY \(a.author.uppercased())"
        
        // Handle attachments
        configureAttachments(for: a)
    }
    
    private func configureAttachments(for announcement: Announcement) {
        // Get attachments from announcement
        attachments = announcement.attachments ?? []
        
        if attachments.isEmpty {
            attachmentButton.isHidden = true
        } else {
            attachmentButton.isHidden = false
            let count = attachments.count
            let title = count == 1 ? "1 attachment" : "\(count) attachments"
            attachmentButton.setTitle(title, for: .normal)
        }
    }
    
    @objc private func attachmentButtonTapped() {
        guard !attachments.isEmpty else { return }
        onAttachmentTapped?(attachments)
    }
}
