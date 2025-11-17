//
//  MentorAnnouncementsViewController.swift
//  iCohort3
//

import UIKit
import SafariServices
import PDFKit

class MentorAnnouncementsViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addTaskButton: UIButton!
    
    private var announcements: [Announcement] = [] {
        didSet { updateUI() }
    }

    private var filteredAnnouncements: [Announcement] = []
    private var searchContainer: UIView!
    private var searchField: UITextField!
    private var searchVisible = false
    private let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
    private let closeButton = UIButton(type: .system)
    private var searchContainerTopConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupTableView()
        setupSearchUI()

        announcements = []
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.addSample() }

        navigationController?.isNavigationBarHidden = true
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = [.top, .bottom]
    }
    
    private func openAddTaskScreen() {
        let vc = AddTaskViewController(nibName: "AddTaskViewController", bundle: nil)
        vc.modalPresentationStyle = .pageSheet

        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.preferredCornerRadius = 24
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
            sheet.prefersGrabberVisible = true
        }

        present(vc, animated: true)
    }

    private func setupViews() {
        searchButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchButton.tintColor = .label
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        let nib = UINib(nibName: "MentorAnnouncementTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "MentorAnnouncementCell")

        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView()
    }

    // MARK: Search UI
    private func setupSearchUI() {
        searchContainer = UIView()
        searchField = UITextField()

        searchContainer.translatesAutoresizingMaskIntoConstraints = false
        searchContainer.backgroundColor = .white
        searchContainer.layer.cornerRadius = 20
        searchContainer.alpha = 0
        searchContainer.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)

        view.addSubview(searchContainer)
        view.bringSubviewToFront(searchButton)

        searchIcon.tintColor = .systemGray
        searchIcon.translatesAutoresizingMaskIntoConstraints = false
        searchContainer.addSubview(searchIcon)

        searchField.placeholder = "Search"
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
        searchContainer.addSubview(searchField)

        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .systemGray
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(hideSearchField), for: .touchUpInside)
        searchContainer.addSubview(closeButton)

        searchContainerTopConstraint = searchContainer.centerYAnchor.constraint(equalTo: searchButton.centerYAnchor)

        NSLayoutConstraint.activate([
            searchContainerTopConstraint,
            searchContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchContainer.trailingAnchor.constraint(equalTo: searchButton.trailingAnchor),
            searchContainer.heightAnchor.constraint(equalToConstant: 45),

            searchIcon.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 12),
            searchIcon.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),

            closeButton.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -12),
            closeButton.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),

            searchField.leadingAnchor.constraint(equalTo: searchIcon.trailingAnchor, constant: 8),
            searchField.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            searchField.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor)
        ])
    }
    
    @IBAction func addTaskButtonTapped(_ sender: Any) {
        openAddTaskScreen()
    }

    // MARK: Actions
    @IBAction func searchButtonTapped(_ sender: UIButton) {
        searchVisible ? hideSearchField() : showSearchField()
    }

    private func showSearchField() {
        searchVisible = true
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut,
            animations: {
                self.searchContainer.alpha = 1
                self.searchContainer.transform = .identity
                self.searchButton.alpha = 0
        }) { _ in
            self.searchButton.isHidden = true
            self.searchField.becomeFirstResponder()
        }
    }

    @objc private func hideSearchField() {
        searchVisible = false
        searchField.resignFirstResponder()
        searchButton.isHidden = false

        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 0,
            options: .curveEaseIn,
            animations: {
                self.searchContainer.alpha = 0
                self.searchContainer.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                self.searchButton.alpha = 1
        }) { _ in
            self.searchField.text = ""
            self.filteredAnnouncements.removeAll()
            self.tableView.reloadData()
        }
    }

    @objc private func searchTextChanged(_ field: UITextField) {
        guard let txt = field.text?.lowercased(), !txt.isEmpty else {
            filteredAnnouncements.removeAll()
            tableView.reloadData()
            return
        }

        filteredAnnouncements = announcements.filter {
            $0.title.lowercased().contains(txt) ||
            $0.body.lowercased().contains(txt) ||
            ($0.tag?.lowercased().contains(txt) ?? false) ||
            $0.author.lowercased().contains(txt)
        }
        tableView.reloadData()
    }

    private func updateUI() {
        let empty = announcements.isEmpty
        placeholderLabel.isHidden = !empty
        tableView.isHidden = empty
        searchButton.isHidden = false

        if !empty { tableView.reloadData() }
    }
    
    // MARK: Edit & Delete Actions
    private func editAnnouncement(at index: Int) {
        let announcement = filteredAnnouncements.isEmpty ? announcements[index] : filteredAnnouncements[index]
        
        let vc = EditAnnouncementViewController(nibName: "AddTaskViewController", bundle: nil)
        vc.announcementToEdit = announcement
        vc.modalPresentationStyle = .pageSheet
        
        // Callback to update the announcement
        vc.onSave = { [weak self] updatedAnnouncement in
            guard let self = self else { return }
            
            // Find and update in main array
            if let mainIndex = self.announcements.firstIndex(where: { $0.id == updatedAnnouncement.id }) {
                self.announcements[mainIndex] = updatedAnnouncement
            }
            
            // Update filtered array if needed
            if !self.filteredAnnouncements.isEmpty {
                if let filteredIndex = self.filteredAnnouncements.firstIndex(where: { $0.id == updatedAnnouncement.id }) {
                    self.filteredAnnouncements[filteredIndex] = updatedAnnouncement
                }
            }
            
            self.tableView.reloadData()
        }

        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.preferredCornerRadius = 24
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
            sheet.prefersGrabberVisible = true
        }

        present(vc, animated: true)
    }
    
    private func deleteAnnouncement(at index: Int) {
        let alert = UIAlertController(
            title: "Delete Announcement",
            message: "Are you sure you want to delete this announcement?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            if self.filteredAnnouncements.isEmpty {
                let announcementToDelete = self.announcements[index]
                self.announcements.removeAll { $0.id == announcementToDelete.id }
            } else {
                let announcementToDelete = self.filteredAnnouncements[index]
                self.announcements.removeAll { $0.id == announcementToDelete.id }
                self.filteredAnnouncements.remove(at: index)
            }
            
            self.tableView.reloadData()
        })
        
        present(alert, animated: true)
    }
    
    private func showAttachments(_ attachments: [AttachmentType]) {
        let vc = AttachmentViewController()
        vc.attachments = attachments
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: Sample Data
    func addSample() {
        let sampleImage = UIImage(named: "sample_attachment") ?? UIImage(systemName: "photo.fill")!
        let pdfURL = Bundle.main.url(forResource: "sample_document", withExtension: "pdf") ?? URL(string: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf")!
        let linkURL = URL(string: "https://www.apple.com/education/")!
        
        announcements.insert(
            Announcement(
                id: UUID(),
                title: "Mentor Sync Session",
                body: "Weekly sync meeting for all mentors tomorrow. Please review the attached materials.",
                tag: "Meeting",
                createdAt: Date(),
                author: "Program Lead",
                attachments: [
                    .image(sampleImage),
                    .pdf("Meeting Agenda.pdf", pdfURL),
                    .link("Apple Education", linkURL)
                ]
            ),
            at: 0
        )
        
        announcements.insert(
            Announcement(
                id: UUID(),
                title: "New Training Resources",
                body: "Check out these new training materials for mentors.",
                tag: "Event",
                createdAt: Date().addingTimeInterval(-3600),
                author: "Training Team",
                attachments: [
                    .link("Training Portal", URL(string: "https://developer.apple.com")!),
                    .image(UIImage(systemName: "book.fill")!)
                ]
            ),
            at: 0
        )
    }
}

// MARK: - Table Data Source
extension MentorAnnouncementsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredAnnouncements.isEmpty ? announcements.count : filteredAnnouncements.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "MentorAnnouncementCell",
            for: indexPath
        ) as? MentorAnnouncementTableViewCell else {
            return UITableViewCell()
        }

        let obj = filteredAnnouncements.isEmpty ? announcements[indexPath.row] : filteredAnnouncements[indexPath.row]
        cell.configure(with: obj)
        cell.selectionStyle = .none
        
        // Handle edit button tap (renamed from info)
        cell.onInfoTapped = { [weak self] in
            self?.editAnnouncement(at: indexPath.row)
        }
        
        // Handle delete button tap
        cell.onDeleteTapped = { [weak self] in
            self?.deleteAnnouncement(at: indexPath.row)
        }
        
        // Handle attachment button tap
        cell.onAttachmentTapped = { [weak self] attachments in
            self?.showAttachments(attachments)
        }
        
        return cell
    }
}

// MARK: - Edit Announcement View Controller
class EditAnnouncementViewController: AddTaskViewController {
    
    var announcementToEdit: Announcement?
    var onSave: ((Announcement) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Pre-fill the form with existing announcement data
        if let announcement = announcementToEdit {
            titleTextField.text = announcement.title
            descriptionTextField.text = announcement.body
            categoryName.text = announcement.tag
            categoryLabel.text = announcement.tag ?? "Label"
            
            // Pre-load attachments
            if let attachments = announcement.attachments {
                for attachment in attachments {
                    switch attachment {
                    case .image(let image):
                        attachedImages.append(image)
                        addAttachmentLabel("Image_\(Date().timeIntervalSince1970).jpg", type: .image)
                        
                    case .pdf(let name, let url):
                        attachedDocumentURLs.append(url)
                        addAttachmentLabel(name, type: .document)
                        
                    case .link(let name, let url):
                        attachedLinks.append(url.absoluteString)
                        let displayName = name.count > 40 ? String(name.prefix(37)) + "..." : name
                        addAttachmentLabel(displayName, type: .link)
                    }
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Pre-select color after view appears (when buttons are ready)
        if let announcement = announcementToEdit {
            if let storedColor = announcement.tagColor {
                selectColorButton(for: storedColor)
            } else if let tag = announcement.tag {
                // Fallback to default colors based on tag type
                if tag.lowercased().contains("event") {
                    selectColorButton(for: UIColor.systemGreen)
                } else {
                    selectColorButton(for: UIColor.systemYellow)
                }
            }
        }
    }
    
    override func doneButtonTapped(_ sender: Any) {
        guard let title = titleTextField.text, !title.isEmpty else {
            showAlert(message: "Please enter a title.")
            return
        }
        
        guard let announcement = announcementToEdit else {
            self.dismiss(animated: true)
            return
        }
        
        // Create attachments array
        var updatedAttachments: [AttachmentType] = []
        
        // Add images
        for image in attachedImages {
            updatedAttachments.append(.image(image))
        }
        
        // Add documents
        for (index, url) in attachedDocumentURLs.enumerated() {
            let name = "Document_\(index + 1).pdf"
            updatedAttachments.append(.pdf(name, url))
        }
        
        // Add links
        for linkString in attachedLinks {
            if let url = URL(string: linkString) {
                updatedAttachments.append(.link(linkString, url))
            }
        }
        
        // Create updated announcement with the selected color
        let updatedAnnouncement = Announcement(
            id: announcement.id,
            title: title,
            body: descriptionTextField.text ?? "",
            tag: categoryName.text?.isEmpty == false ? categoryName.text : nil,
            tagColor: selectedColor,  // Save the selected color
            createdAt: announcement.createdAt,
            author: announcement.author,
            attachments: updatedAttachments.isEmpty ? nil : updatedAttachments
        )
        
        // Call the save callback
        onSave?(updatedAnnouncement)
        
        self.dismiss(animated: true)
    }
}

// MARK: - Attachment Viewer
class AttachmentViewController: UIViewController {
    
    var attachments: [AttachmentType] = []
    
    private var tableView: UITableView!
    private var closeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupCloseButton()
        setupTableView()
    }
    
    private func setupCloseButton() {
        closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.backgroundColor = .white
        closeButton.layer.cornerRadius = 20
        closeButton.tintColor = .label
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.backgroundColor = .systemBackground
        view.addSubview(closeButton)
        
        let titleLabel = UILabel()
        titleLabel.text = "Attachments"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupTableView() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AttachmentTableViewCell.self, forCellReuseIdentifier: "AttachmentCell")
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 70),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    private func openAttachment(_ attachment: AttachmentType) {
        switch attachment {
        case .image(let image):
            let imageVC = ImageViewController()
            imageVC.image = image
            imageVC.modalPresentationStyle = .fullScreen
            present(imageVC, animated: true)
            
        case .pdf(_, let url):
            let pdfVC = PDFViewController()
            pdfVC.pdfURL = url
            pdfVC.modalPresentationStyle = .fullScreen
            present(pdfVC, animated: true)
            
        case .link(_, let url):
            let safariVC = SFSafariViewController(url: url)
            present(safariVC, animated: true)
        }
    }
}

// MARK: - AttachmentViewController Table Delegate
extension AttachmentViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return attachments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AttachmentCell", for: indexPath) as! AttachmentTableViewCell
        cell.configure(with: attachments[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        openAttachment(attachments[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}

// MARK: - Attachment Table Cell
class AttachmentTableViewCell: UITableViewCell {
    
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let chevronView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .systemBlue
        contentView.addSubview(iconView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        contentView.addSubview(titleLabel)
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel
        contentView.addSubview(subtitleLabel)
        
        chevronView.translatesAutoresizingMaskIntoConstraints = false
        chevronView.image = UIImage(systemName: "chevron.right")
        chevronView.tintColor = .tertiaryLabel
        contentView.addSubview(chevronView)
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: chevronView.leadingAnchor, constant: -8),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            chevronView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chevronView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chevronView.widthAnchor.constraint(equalToConstant: 20),
            chevronView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func configure(with attachment: AttachmentType) {
        switch attachment {
        case .image(let image):
            iconView.image = image
            iconView.contentMode = .scaleAspectFill
            iconView.layer.cornerRadius = 8
            iconView.clipsToBounds = true
            titleLabel.text = "Image"
            subtitleLabel.text = "Tap to view"
            
        case .pdf(let title, _):
            iconView.image = UIImage(systemName: "doc.fill")
            iconView.contentMode = .scaleAspectFit
            iconView.layer.cornerRadius = 0
            iconView.clipsToBounds = false
            titleLabel.text = title
            subtitleLabel.text = "PDF Document"
            
        case .link(let title, let url):
            iconView.image = UIImage(systemName: "link")
            iconView.contentMode = .scaleAspectFit
            iconView.layer.cornerRadius = 0
            iconView.clipsToBounds = false
            titleLabel.text = title
            subtitleLabel.text = url.host ?? url.absoluteString
        }
    }
}

// MARK: - Image Viewer
class ImageViewController: UIViewController, UIScrollViewDelegate {
    
    var image: UIImage?
    private var scrollView: UIScrollView!
    private var imageView: UIImageView!
    private var closeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupScrollView()
        setupImageView()
        setupCloseButton()
    }
    
    private func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupImageView() {
        imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }
    
    private func setupCloseButton() {
        closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

// MARK: - PDF Viewer
class PDFViewController: UIViewController {
    
    var pdfURL: URL?
    private var pdfView: PDFView!
    private var closeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupPDFView()
        setupCloseButton()
        loadPDF()
    }
    
    private func setupPDFView() {
        pdfView = PDFView()
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        view.addSubview(pdfView)
        
        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupCloseButton() {
        closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .label
        closeButton.backgroundColor = .systemBackground
        closeButton.layer.cornerRadius = 22
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func loadPDF() {
        guard let url = pdfURL else { return }
        
        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}




