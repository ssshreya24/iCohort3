//
//  MentorAnnouncementTableViewCell.swift
//  iCohort3
//

import UIKit

class MentorAnnouncementTableViewCell: UITableViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var metaLabel: UILabel!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var attacthmentButton: UIButton!
    
    // Closure to handle actions from the cell
    var onInfoTapped: (() -> Void)?
    var onDeleteTapped: (() -> Void)?
    var onAttachmentTapped: (([AttachmentType]) -> Void)?
    
    private var attachments: [AttachmentType] = []
    private let darkCardColor = UIColor(red: 0.27, green: 0.30, blue: 0.37, alpha: 0.98)
    
    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        AppTheme.styleCard(containerView, cornerRadius: 14)

        tagLabel.layer.masksToBounds = true
        tagLabel.layer.cornerRadius = 12
        tagLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        tagLabel.textColor = .white
        tagLabel.textAlignment = .center
        
        // Setup info button action
        infoButton.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
        
        // Setup attachment button
        attacthmentButton.addTarget(self, action: #selector(attachmentButtonTapped), for: .touchUpInside)
        setupAttachmentButton()
        applyTheme()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            applyTheme()
        }
    }
    
    private func setupAttachmentButton() {
        attacthmentButton.setTitleColor(.systemBlue, for: .normal)
        attacthmentButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        
        // Set the paperclip icon
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let paperclipImage = UIImage(systemName: "paperclip", withConfiguration: config)
        attacthmentButton.setImage(paperclipImage, for: .normal)
        attacthmentButton.tintColor = .systemBlue
        
        // Position image to the left of text
        attacthmentButton.semanticContentAttribute = .forceLeftToRight
    }

    func configure(with a: Announcement) {
        titleLabel.text = a.title
        bodyLabel.text = a.body
        
        if let t = a.tag {
            tagLabel.isHidden = false
            tagLabel.text = "\(t)    "

            // Use stored color if available, otherwise use default logic
            if let storedColor = a.tagColor {
                tagLabel.backgroundColor = storedColor
            } else if t.lowercased().contains("event") {
                tagLabel.backgroundColor = UIColor(red: 0.18, green: 0.78, blue: 0.42, alpha: 1)
            } else {
                tagLabel.backgroundColor = UIColor(red: 0.95, green: 0.74, blue: 0.18, alpha: 1)
            }
        } else {
            tagLabel.isHidden = true
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM • h:mm a"
        metaLabel.text = "\(formatter.string(from: a.createdAt)) • BY \(a.author.uppercased())"
        
        // Handle attachments
        configureAttachments(for: a)
    }
    
    private func configureAttachments(for announcement: Announcement) {
        attachments = announcement.attachments ?? []
        
        if attachments.isEmpty {
            attacthmentButton.isHidden = true
        } else {
            attacthmentButton.isHidden = false
            let count = attachments.count
            let title = count == 1 ? "1 attachment" : "\(count) attachments"
            attacthmentButton.setTitle(title, for: .normal)
        }
    }
    
    @objc private func attachmentButtonTapped() {
        guard !attachments.isEmpty else { return }
        onAttachmentTapped?(attachments)
    }
    
    @objc private func infoButtonTapped() {
        guard let viewController = findViewController() else { return }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // Edit action (changed from Info)
        let editAction = UIAlertAction(title: "Edit", style: .default) { [weak self] _ in
            self?.onInfoTapped?()
        }
        if let editImage = UIImage(systemName: "pencil") {
            editAction.setValue(editImage, forKey: "image")
        }
        
        // Delete action
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.onDeleteTapped?()
        }
        if let deleteImage = UIImage(systemName: "trash") {
            deleteAction.setValue(deleteImage, forKey: "image")
        }
        
        // Cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(editAction)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        // For iPad support
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = infoButton
            popoverController.sourceRect = infoButton.bounds
        }
        
        viewController.present(alert, animated: true)
    }
    
    // Helper to find the view controller
    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            if let viewController = responder as? UIViewController {
                return viewController
            }
            responder = responder?.next
        }
        return nil
    }
    
    private func applyTheme() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        containerView.backgroundColor = isDarkMode ? darkCardColor : .white
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = AppTheme.borderColor.resolvedColor(with: traitCollection).cgColor
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = isDarkMode ? 0.10 : 0.04
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = isDarkMode ? 8 : 12
        titleLabel.textColor = isDarkMode ? .white : .label
        bodyLabel.textColor = isDarkMode ? UIColor(white: 0.86, alpha: 1) : .secondaryLabel
        metaLabel.textColor = isDarkMode ? UIColor(white: 0.68, alpha: 1) : .tertiaryLabel
        infoButton.tintColor = isDarkMode ? .white : .label
        attacthmentButton.setTitleColor(isDarkMode ? .white : .systemBlue, for: .normal)
        attacthmentButton.tintColor = isDarkMode ? .white : .systemBlue
    }
}
