//
//  MentorAnnouncementsViewController.swift
//  iCohort3
//

import UIKit
import SafariServices
import PDFKit
import Supabase

class MentorAnnouncementsViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addTaskButton: UIButton!
    
    private var announcements: [Announcement] = [] {
        didSet { updateUI() }
    }
    
    // Store database IDs mapped to announcement UUIDs
    private var announcementDatabaseIDs: [UUID: Int] = [:]

    private var filteredAnnouncements: [Announcement] = []
    private var searchContainer: UIView!
    private var searchField: UITextField!
    private var searchVisible = false
    private let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
    private let closeButton = UIButton(type: .system)
    private var searchContainerTopConstraint: NSLayoutConstraint!
    
    // Real-time subscription
    private var realtimeTask: Task<Void, Never>?
    private var reloadDebounceTask: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        setupTableView()
        setupSearchUI()
        applyTheme()
        
        navigationController?.isNavigationBarHidden = true
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = [.top, .bottom]
        
        loadAnnouncementsFromSupabase()
        subscribeToRealtimeUpdates()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        AppTheme.applyScreenBackground(to: view)
        tableView.superview?.backgroundColor = .clear
        styleFloatingButton(searchButton, imageName: "magnifyingglass")
        styleFloatingButton(addTaskButton, imageName: "plus")
        styleSearchContainer()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("🔄 View appeared, reloading announcements")
        loadAnnouncementsFromSupabase()
    }
    
    private func debouncedReload() {
        reloadDebounceTask?.cancel()
        reloadDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            if !Task.isCancelled {
                loadAnnouncementsFromSupabase()
            }
        }
    }

    
    deinit {
            // Cancel the real-time subscription when the view controller is deallocated
            realtimeTask?.cancel()
        }
    
    private func subscribeToRealtimeUpdates() {
        realtimeTask = Task {
            let channel = SupabaseManager.shared.client.channel("mentor_announcements_changes")
            
            let changeStream = channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "mentor_announcements"
            )
            
            let updateStream = channel.postgresChange(
                UpdateAction.self,
                schema: "public",
                table: "mentor_announcements"
            )
            
            let deleteStream = channel.postgresChange(
                DeleteAction.self,
                schema: "public",
                table: "mentor_announcements"
            )
            
            do {
                try await channel.subscribeWithError()
                print("✅ Subscribed to real-time updates")
                
                // Listen for all types of changes - moved inside the do block
                Task {
                    for await _ in changeStream {
                        print("📡 INSERT detected")
                        await MainActor.run {
                            self.loadAnnouncementsFromSupabase()
                        }
                    }
                }
                
                Task {
                    for await _ in updateStream {
                        print("📡 UPDATE detected")
                        await MainActor.run {
                            self.loadAnnouncementsFromSupabase()
                        }
                    }
                }
                
                Task {
                    for await _ in deleteStream {
                        print("📡 DELETE detected")
                        await MainActor.run {
                            self.loadAnnouncementsFromSupabase()
                        }
                    }
                }
            } catch {
                print("❌ Failed to subscribe to real-time updates:", error)
                return
            }
        }
    }

    private func loadAnnouncementsFromSupabase() {
        Task {
            do {
                let rows = try await SupabaseManager.shared.fetchMentorAnnouncements()
                print("Fetched rows:", rows.count)

                // ISO 8601 with / without fractional seconds
                let fmtFrac = ISO8601DateFormatter()
                fmtFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let fmtPlain = ISO8601DateFormatter()

                // Create a temporary mapping to preserve existing UUIDs
                var existingIDMap: [Int: UUID] = [:]
                for (uuid, dbId) in announcementDatabaseIDs {
                    existingIDMap[dbId] = uuid
                }

                let mapped: [Announcement] = rows.map { row in
                    let dateString = row.created_at ?? ""
                    let date =
                        fmtFrac.date(from: dateString) ??
                        fmtPlain.date(from: dateString) ??
                        Date()

                    let color = row.color_hex.flatMap { UIColor.fromHex($0) }
                    let decoded = AnnouncementPayloadCodec.decodeDescription(row.description)
                    
                    // Reuse existing UUID if available, otherwise create new one
                    let uuid = existingIDMap[row.id] ?? UUID()

                    return Announcement(
                        id: uuid,
                        title: row.title,
                        body: decoded.body,
                        tag: row.category,
                        tagColor: color,
                        createdAt: date,
                        author: row.author ?? "Mentor",
                        attachments: decoded.attachments.isEmpty ? nil : decoded.attachments
                    )
                }

                await MainActor.run {
                    // Clear and rebuild the mapping
                    self.announcementDatabaseIDs.removeAll()
                    for (index, row) in rows.enumerated() {
                        self.announcementDatabaseIDs[mapped[index].id] = row.id
                    }
                    
                    self.announcements = mapped
                    
                    // Update filtered results if search is active
                    if self.searchVisible, let searchText = self.searchField.text?.lowercased(), !searchText.isEmpty {
                        self.filteredAnnouncements = mapped.filter {
                            $0.title.lowercased().contains(searchText) ||
                            $0.body.lowercased().contains(searchText) ||
                            ($0.tag?.lowercased().contains(searchText) ?? false) ||
                            $0.author.lowercased().contains(searchText)
                        }
                    }
                    
                    print("✅ Updated announcements on main thread, count: \(self.announcements.count)")
                }
            } catch {
                print("❌ Failed to fetch announcements:", error)
                await MainActor.run {
                    self.placeholderLabel.text = "Error loading announcements"
                    self.placeholderLabel.isHidden = false
                    self.tableView.isHidden = true
                }
            }
        }
    }
    
    private func openAddTaskScreen() {
            let vc = AddTaskViewController(nibName: "AddTaskViewController", bundle: nil)
            
            // ✅ Set the delegate
            vc.delegate = self
            
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
        applyTheme()
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        let nib = UINib(nibName: "MentorAnnouncementTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "MentorAnnouncementCell")

        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .clear
    }

    // MARK: Search UI
    private func setupSearchUI() {
        searchContainer = UIView()
        searchField = UITextField()

        searchContainer.translatesAutoresizingMaskIntoConstraints = false
        searchContainer.backgroundColor = .clear
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
        
        styleSearchContainer()
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
            updateEmptyState() // ✅ Update empty state
            return
        }

        filteredAnnouncements = announcements.filter {
            $0.title.lowercased().contains(txt) ||
            $0.body.lowercased().contains(txt) ||
            ($0.tag?.lowercased().contains(txt) ?? false) ||
            $0.author.lowercased().contains(txt)
        }
        tableView.reloadData()
        updateEmptyState() // ✅ Update empty state
    }

    private func updateUI() {
        let empty = announcements.isEmpty
        tableView.isHidden = empty
        searchButton.isHidden = false

        if !empty {
            tableView.reloadData()
        }
        
        updateEmptyState() // ✅ Update empty state
    }
    
    private func applyTheme() {
        AppTheme.applyScreenBackground(to: view)
        
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
                self.applyTheme()
            }
        }
        
        view.subviews.forEach { subview in
            if subview !== tableView && subview !== searchContainer && subview !== searchButton && subview !== addTaskButton {
                subview.backgroundColor = .clear
            }
        }
        titleLabel.textColor = .label
        placeholderLabel.textColor = .secondaryLabel
        tableView.backgroundColor = .clear
        tableView.superview?.backgroundColor = .clear
        styleFloatingButton(searchButton, imageName: "magnifyingglass")
        styleFloatingButton(addTaskButton, imageName: "plus")
        styleSearchContainer()
    }
    
    private func styleFloatingButton(_ button: UIButton, imageName: String?) {
        let foreground = traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
        var config = UIButton.Configuration.plain()
        if let imageName, !imageName.isEmpty {
            config.image = UIImage(systemName: imageName)
        } else if let currentImage = button.currentImage {
            config.image = currentImage
        }
        config.baseForegroundColor = foreground
        config.background.backgroundColor = .clear
        config.cornerStyle = .capsule
        button.configuration = config
        AppTheme.styleNativeFloatingControl(button, cornerRadius: button.bounds.height / 2)
        button.backgroundColor = .clear
        button.tintColor = foreground
        button.setTitleColor(foreground, for: .normal)
    }
    
    private func styleSearchContainer() {
        guard searchContainer != nil else { return }
        AppTheme.styleNativeFloatingControl(searchContainer, cornerRadius: 20)
        searchContainer.backgroundColor = .clear
        searchIcon.tintColor = .secondaryLabel
        searchField.textColor = .label
        searchField.tintColor = AppTheme.accent
        searchField.attributedPlaceholder = NSAttributedString(
            string: "Search",
            attributes: [.foregroundColor: UIColor.secondaryLabel]
        )
        closeButton.tintColor = .secondaryLabel
    }
    
    // ✅ NEW METHOD: Smart empty state handling
    private func updateEmptyState() {
        let isSearchActive = searchVisible && !(searchField.text?.isEmpty ?? true)
        
        if isSearchActive {
            // Searching mode
            if filteredAnnouncements.isEmpty {
                placeholderLabel.text = "No announcements found"
                placeholderLabel.isHidden = false
                tableView.isHidden = true
            } else {
                placeholderLabel.isHidden = true
                tableView.isHidden = false
            }
        } else {
            // Normal mode (not searching)
            if announcements.isEmpty {
                placeholderLabel.text = "No announcements yet"
                placeholderLabel.isHidden = false
                tableView.isHidden = true
            } else {
                placeholderLabel.isHidden = true
                tableView.isHidden = false
            }
        }
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
            
            // Get the database ID for this announcement
            guard let dbId = self.announcementDatabaseIDs[updatedAnnouncement.id] else {
                print("❌ No database ID found for announcement")
                return
            }
            
            // Update in Supabase
            Task {
                do {
                    try await SupabaseManager.shared.updateMentorAnnouncement(
                        id: dbId,
                        title: updatedAnnouncement.title,
                        description: AnnouncementPayloadCodec.encodedDescription(
                            body: updatedAnnouncement.body,
                            attachments: updatedAnnouncement.attachments ?? []
                        ),
                        category: updatedAnnouncement.tag,
                        colorHex: updatedAnnouncement.tagColor?.toHexString()
                    )
                    
                    // Update local data
                    await MainActor.run {
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
                } catch {
                    print("❌ Failed to update announcement:", error)
                    await MainActor.run {
                        self.showAlert(title: "Error", message: "Failed to update announcement: \(error.localizedDescription)")
                    }
                }
            }
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
            
            let announcementToDelete: Announcement
            if self.filteredAnnouncements.isEmpty {
                announcementToDelete = self.announcements[index]
            } else {
                announcementToDelete = self.filteredAnnouncements[index]
            }
            
            // Get the database ID
            guard let dbId = self.announcementDatabaseIDs[announcementToDelete.id] else {
                print("❌ No database ID found for announcement")
                return
            }
            
            // Delete from Supabase
            Task {
                do {
                    try await SupabaseManager.shared.deleteAnnouncement(id: dbId)
                    
                    // Update local data
                    await MainActor.run {
                        self.announcements.removeAll { $0.id == announcementToDelete.id }
                        self.filteredAnnouncements.removeAll { $0.id == announcementToDelete.id }
                        self.announcementDatabaseIDs.removeValue(forKey: announcementToDelete.id)
                        self.tableView.reloadData()
                    }
                } catch {
                    print("❌ Failed to delete announcement:", error)
                    await MainActor.run {
                        self.showAlert(title: "Error", message: "Failed to delete announcement: \(error.localizedDescription)")
                    }
                }
            }
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
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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
                        draftAttachments.append(.image(name: "Image_\(Date().timeIntervalSince1970).jpg", image: image))
                        
                    case .pdf(let name, let url):
                        draftAttachments.append(.document(name: name, url: url))
                        
                    case .link(let name, let url):
                        draftAttachments.append(.link(title: name, urlString: url.absoluteString))
                    }
                }
                syncLegacyAttachmentStorage()
                renderDraftAttachments()
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
        
        let updatedAttachments = currentAnnouncementAttachments()
        
        // Create updated announcement with the selected color
        let updatedAnnouncement = Announcement(
            id: announcement.id,
            title: title,
            body: descriptionTextField.text ?? "",
            tag: categoryName.text?.isEmpty == false ? categoryName.text : nil,
            tagColor: selectedColor,
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

extension MentorAnnouncementsViewController: AddTaskViewControllerDelegate {
    func didSaveAnnouncement() {
        // Reload data from Supabase when a new announcement is saved
        print("🔄 Delegate called - reloading announcements...")
        loadAnnouncementsFromSupabase()
    }
}
