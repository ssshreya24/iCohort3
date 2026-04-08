//
//  TaskDetailViewController.swift
//  iCohort3


import UIKit
internal import UniformTypeIdentifiers
import PostgREST
import Supabase
import SafariServices

// NOTE: DashboardTask is declared in DashboardTask.swift (shared model file).

// MARK: - In-memory attachment model


private struct AttachmentPayload {
    let filename: String
    let fileType: String
    let base64Data: String   // base64-encoded file bytes
    let isLink: Bool

    /// Convenience for URL-only attachments (no binary data)
    static func link(_ url: String) -> AttachmentPayload {
        AttachmentPayload(filename: url, fileType: "text/url", base64Data: "", isLink: true)
    }
}

// MARK: - ViewController

class TaskDetailViewController: UIViewController {

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let contentStackView = UIStackView()
    private let backButton = UIButton(type: .system)

    // Title Card
    private let titleCard = UIView()
    private let taskTitleLabel = UILabel()
    private let dueDateContainerView = UIView()
    private let dueDateLabel = UILabel()
    private let dueTextLabel = UILabel()

    // Assigned To Card
    private let assignedToContainerView = UIView()
    private let resourcesContainerView = UIView()
    private let assigneeImageView = UIImageView()
    private let assigneeNameLabel = UILabel()
    private let assignedToTitleLabel = UILabel()

    // Assigned By (mentor)
    private let assignedByContainerView = UIView()
    private let assignedByNameLabel = UILabel()
    private let assignedByTitleLabel = UILabel()

    // Attachment Card
    private let attachmentContainerView = UIView()
    private let attachmentIconButton = UIButton(type: .system)
    private let attachmentsStackView = UIStackView()
    private let attachmentTitleLabel = UILabel()

    // Submit To
    private let submitToContainerView = UIView()
    private let submitToButton = UIButton(type: .system)
    private let submitToTitleLabel = UILabel()

    // Submit Button
    private let submitButton = UIButton(type: .system)

    // Height Constraints
    private var attachmentContainerHeightConstraint: NSLayoutConstraint!
    private var resourcesContainerHeightConstraint: NSLayoutConstraint!

    // Resources Section
    private let resourcesStackView = UIStackView()
    private let resourcesTitleLabel = UILabel()

    // MARK: - Task Model
    var task: DashboardTask?

    // MARK: - State

    private var isSubmitted = false
    private var mentorOptions: [(name: String, personId: String)] = []
    private var selectedSubmitTo: String = ""
    private var mentorFeedbackText: String?
    private var loadingIndicator: UIActivityIndicatorView?
    private var loadingOverlayView: UIView?

    /// Pending attachments the student has picked — cleared on submit
    private var pendingAttachments: [AttachmentPayload] = []
    private let cardCornerRadius: CGFloat = 20
    private let rowCornerRadius: CGFloat = 12

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        enableKeyboardDismissOnTap()
        buildLayout()
        applyConstraints()
        setupUI()
        setupBackButton()
        setupMentorUI()
        setupLoadingIndicator()

        if let t = task { configure(with: t) }

        Task { await loadSupabaseData(showOverlayLoader: true) }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyTheme()
    }

    @available(iOS, deprecated: 17.0, message: "Use registerForTraitChanges")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            applyTheme()
        }
    }

    // MARK: - Back Button

    private func setupBackButton() {
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.layer.cornerRadius = 22
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        view.addSubview(backButton)
        view.bringSubviewToFront(backButton)
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func backButtonTapped() { dismiss(animated: true) }

    // MARK: - Mentor UI placeholder

    private func setupMentorUI() {
        assignedByNameLabel.text      = "Loading..."
        assignedByNameLabel.textColor = .secondaryLabel
        assignedByNameLabel.font      = UIFont.systemFont(ofSize: 16)

        submitToButton.setTitle("Select Mentor", for: .normal)
        submitToButton.setTitleColor(.secondaryLabel, for: .normal)
        submitToButton.titleLabel?.font       = UIFont.systemFont(ofSize: 16)
    }

    // MARK: - Theme

    private func applyTheme() {
        AppTheme.applyScreenBackground(to: view)
        contentView.backgroundColor = .clear
        scrollView.backgroundColor = .clear

        let isDark = traitCollection.userInterfaceStyle == .dark
        let foreground = isDark ? UIColor.white : UIColor.black
        let accent = AppTheme.buttonColor
        let rowBackground = isDark
            ? UIColor.white.withAlphaComponent(0.10)
            : UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1)

        let cards: [UIView?] = [
            titleCard, assignedToContainerView, attachmentContainerView,
            assignedByContainerView, submitToContainerView, resourcesContainerView
        ]
        cards.forEach {
            guard let card = $0 else { return }
            AppTheme.styleElevatedCard(card, cornerRadius: cardCornerRadius)
        }

        let sectionLabels = [
            dueTextLabel,
            assignedToTitleLabel,
            assignedByTitleLabel,
            resourcesTitleLabel,
            attachmentTitleLabel,
            submitToTitleLabel
        ]
        sectionLabels.forEach {
            $0.textColor = .label
            $0.font = .systemFont(ofSize: 16, weight: .medium)
            $0.setContentHuggingPriority(.required, for: .horizontal)
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        }

        taskTitleLabel.textColor = .label
        dueDateLabel.textColor = .secondaryLabel
        assigneeNameLabel.textColor = .label
        assignedByNameLabel.textColor = .secondaryLabel
        submitToButton.setTitleColor(.label, for: .normal)
        submitToButton.tintColor = accent
        attachmentIconButton.tintColor = accent
        submitButton.backgroundColor = accent
        submitButton.setTitleColor(.white, for: .normal)

        let backConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        var buttonConfig = UIButton.Configuration.plain()
        buttonConfig.image = UIImage(systemName: "chevron.left", withConfiguration: backConfig)
        buttonConfig.baseForegroundColor = foreground
        buttonConfig.background.backgroundColor = .clear
        buttonConfig.cornerStyle = .capsule
        backButton.configuration = buttonConfig
        AppTheme.styleNativeFloatingControl(backButton, cornerRadius: 22)
        backButton.backgroundColor = .clear
        backButton.tintColor = foreground

        // Resource row icons: re-tint to adapt to mode
        func reTintSubviews(in stackView: UIStackView?) {
            stackView?.arrangedSubviews.forEach { row in
                row.layer.cornerRadius = rowCornerRadius
                row.clipsToBounds = true
                row.subviews.compactMap { $0 as? UIImageView }.forEach { $0.tintColor = AppTheme.buttonColor }
                row.subviews.compactMap { $0 as? UILabel }.forEach { $0.textColor = .label }
                row.backgroundColor = rowBackground
            }
        }
        reTintSubviews(in: resourcesStackView)
        reTintSubviews(in: attachmentsStackView)
    }

    // MARK: - UI Setup

    // MARK: - UI Construction

    private func buildLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.spacing = 20
        contentStackView.alignment = .fill
        contentView.addSubview(contentStackView)

        // Title Card
        titleCard.translatesAutoresizingMaskIntoConstraints = false
        taskTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        taskTitleLabel.numberOfLines = 0
        taskTitleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        
        dueDateLabel.translatesAutoresizingMaskIntoConstraints = false
        dueDateLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        let dueRow = UIStackView()
        dueRow.translatesAutoresizingMaskIntoConstraints = false
        dueRow.axis = .horizontal
        dueRow.spacing = 8
        dueRow.alignment = .center
        
        let calIcon = UIImageView(image: UIImage(systemName: "calendar"))
        calIcon.tintColor = AppTheme.buttonColor
        calIcon.contentMode = .scaleAspectFit
        calIcon.widthAnchor.constraint(equalToConstant: 20).isActive = true
        calIcon.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        dueTextLabel.text = "Due Date"
        dueRow.addArrangedSubview(calIcon)
        dueRow.addArrangedSubview(dueTextLabel)
        dueRow.addArrangedSubview(UIView()) // Flexible space
        dueRow.addArrangedSubview(dueDateLabel)
        
        titleCard.addSubview(taskTitleLabel)
        titleCard.addSubview(dueRow)
        
        NSLayoutConstraint.activate([
            taskTitleLabel.topAnchor.constraint(equalTo: titleCard.topAnchor, constant: 20),
            taskTitleLabel.leadingAnchor.constraint(equalTo: titleCard.leadingAnchor, constant: 16),
            taskTitleLabel.trailingAnchor.constraint(equalTo: titleCard.trailingAnchor, constant: -16),
            
            dueRow.topAnchor.constraint(equalTo: taskTitleLabel.bottomAnchor, constant: 16),
            dueRow.leadingAnchor.constraint(equalTo: titleCard.leadingAnchor, constant: 16),
            dueRow.trailingAnchor.constraint(equalTo: titleCard.trailingAnchor, constant: -16),
            dueRow.bottomAnchor.constraint(equalTo: titleCard.bottomAnchor, constant: -20)
        ])
        contentStackView.addArrangedSubview(titleCard)

        // Assigned To Card
        assignedToContainerView.translatesAutoresizingMaskIntoConstraints = false
        assignedToTitleLabel.text = "Assigned To"
        assigneeImageView.translatesAutoresizingMaskIntoConstraints = false
        assigneeImageView.contentMode = .scaleAspectFill
        assigneeImageView.clipsToBounds = true
        assigneeImageView.layer.cornerRadius = 18
        
        assigneeNameLabel.translatesAutoresizingMaskIntoConstraints = false
        assigneeNameLabel.font = .systemFont(ofSize: 16)
        assigneeNameLabel.textAlignment = .right
        assigneeNameLabel.lineBreakMode = .byTruncatingTail

        let assigneeTrailingStack = UIStackView(arrangedSubviews: [assigneeImageView, assigneeNameLabel])
        assigneeTrailingStack.translatesAutoresizingMaskIntoConstraints = false
        assigneeTrailingStack.axis = .horizontal
        assigneeTrailingStack.spacing = 12
        assigneeTrailingStack.alignment = .center

        let assignedToRow = UIStackView(arrangedSubviews: [assignedToTitleLabel, UIView(), assigneeTrailingStack])
        assignedToRow.translatesAutoresizingMaskIntoConstraints = false
        assignedToRow.axis = .horizontal
        assignedToRow.spacing = 12
        assignedToRow.alignment = .center
        
        assignedToContainerView.addSubview(assignedToRow)
        
        NSLayoutConstraint.activate([
            assigneeImageView.widthAnchor.constraint(equalToConstant: 36),
            assigneeImageView.heightAnchor.constraint(equalToConstant: 36),
            assignedToRow.topAnchor.constraint(equalTo: assignedToContainerView.topAnchor, constant: 14),
            assignedToRow.leadingAnchor.constraint(equalTo: assignedToContainerView.leadingAnchor, constant: 16),
            assignedToRow.trailingAnchor.constraint(equalTo: assignedToContainerView.trailingAnchor, constant: -16),
            assignedToRow.bottomAnchor.constraint(equalTo: assignedToContainerView.bottomAnchor, constant: -14),
            assignedToContainerView.heightAnchor.constraint(equalToConstant: 60)
        ])
        contentStackView.addArrangedSubview(assignedToContainerView)

        // Assigned By Card
        assignedByContainerView.translatesAutoresizingMaskIntoConstraints = false
        assignedByTitleLabel.text = "Assigned By"
        assignedByNameLabel.translatesAutoresizingMaskIntoConstraints = false
        assignedByNameLabel.font = .systemFont(ofSize: 16)
        assignedByNameLabel.textAlignment = .right
        assignedByNameLabel.lineBreakMode = .byTruncatingTail

        let assignedByRow = UIStackView(arrangedSubviews: [assignedByTitleLabel, UIView(), assignedByNameLabel])
        assignedByRow.translatesAutoresizingMaskIntoConstraints = false
        assignedByRow.axis = .horizontal
        assignedByRow.spacing = 12
        assignedByRow.alignment = .center
        
        assignedByContainerView.addSubview(assignedByRow)
        
        NSLayoutConstraint.activate([
            assignedByRow.topAnchor.constraint(equalTo: assignedByContainerView.topAnchor, constant: 14),
            assignedByRow.leadingAnchor.constraint(equalTo: assignedByContainerView.leadingAnchor, constant: 16),
            assignedByRow.trailingAnchor.constraint(equalTo: assignedByContainerView.trailingAnchor, constant: -16),
            assignedByRow.bottomAnchor.constraint(equalTo: assignedByContainerView.bottomAnchor, constant: -14),
            assignedByContainerView.heightAnchor.constraint(equalToConstant: 56)
        ])
        contentStackView.addArrangedSubview(assignedByContainerView)

        // Resources Card
        resourcesContainerView.translatesAutoresizingMaskIntoConstraints = false
        resourcesTitleLabel.text = "Resources"
        
        resourcesStackView.translatesAutoresizingMaskIntoConstraints = false
        resourcesStackView.axis = .vertical
        resourcesStackView.spacing = 8
        resourcesStackView.alignment = .fill
        resourcesStackView.distribution = .fill
        
        resourcesContainerView.addSubview(resourcesTitleLabel)
        resourcesContainerView.addSubview(resourcesStackView)
        
        resourcesContainerHeightConstraint = resourcesContainerView.heightAnchor.constraint(equalToConstant: 100)
        resourcesContainerHeightConstraint.priority = .defaultHigh
        
        NSLayoutConstraint.activate([
            resourcesTitleLabel.topAnchor.constraint(equalTo: resourcesContainerView.topAnchor, constant: 12),
            resourcesTitleLabel.leadingAnchor.constraint(equalTo: resourcesContainerView.leadingAnchor, constant: 16),
            
            resourcesStackView.topAnchor.constraint(equalTo: resourcesTitleLabel.bottomAnchor, constant: 12),
            resourcesStackView.leadingAnchor.constraint(equalTo: resourcesContainerView.leadingAnchor, constant: 16),
            resourcesStackView.trailingAnchor.constraint(equalTo: resourcesContainerView.trailingAnchor, constant: -16),
            resourcesStackView.bottomAnchor.constraint(equalTo: resourcesContainerView.bottomAnchor, constant: -12),
            resourcesContainerHeightConstraint
        ])
        contentStackView.addArrangedSubview(resourcesContainerView)

        // Attachment Card
        attachmentContainerView.translatesAutoresizingMaskIntoConstraints = false
        attachmentTitleLabel.text = "Add Attachment"
        
        attachmentIconButton.translatesAutoresizingMaskIntoConstraints = false
        attachmentIconButton.setImage(UIImage(systemName: "paperclip"), for: .normal)
        attachmentIconButton.tintColor = AppTheme.buttonColor
        attachmentIconButton.addTarget(self, action: #selector(attachmentButtonTapped), for: .touchUpInside)
        
        attachmentsStackView.translatesAutoresizingMaskIntoConstraints = false
        attachmentsStackView.axis = .vertical
        attachmentsStackView.spacing = 8
        attachmentsStackView.alignment = .fill
        attachmentsStackView.distribution = .fill

        let attachmentHeaderRow = UIStackView(arrangedSubviews: [attachmentTitleLabel, UIView(), attachmentIconButton])
        attachmentHeaderRow.translatesAutoresizingMaskIntoConstraints = false
        attachmentHeaderRow.axis = .horizontal
        attachmentHeaderRow.spacing = 12
        attachmentHeaderRow.alignment = .center
        
        attachmentContainerView.addSubview(attachmentHeaderRow)
        attachmentContainerView.addSubview(attachmentsStackView)
        
        attachmentContainerHeightConstraint = attachmentContainerView.heightAnchor.constraint(equalToConstant: 92)
        attachmentContainerHeightConstraint.priority = .defaultHigh
        
        NSLayoutConstraint.activate([
            attachmentHeaderRow.topAnchor.constraint(equalTo: attachmentContainerView.topAnchor, constant: 16),
            attachmentHeaderRow.leadingAnchor.constraint(equalTo: attachmentContainerView.leadingAnchor, constant: 16),
            attachmentHeaderRow.trailingAnchor.constraint(equalTo: attachmentContainerView.trailingAnchor, constant: -16),
            attachmentIconButton.widthAnchor.constraint(equalToConstant: 30),
            attachmentIconButton.heightAnchor.constraint(equalToConstant: 30),
            
            attachmentsStackView.topAnchor.constraint(equalTo: attachmentHeaderRow.bottomAnchor, constant: 12),
            attachmentsStackView.leadingAnchor.constraint(equalTo: attachmentContainerView.leadingAnchor, constant: 16),
            attachmentsStackView.trailingAnchor.constraint(equalTo: attachmentContainerView.trailingAnchor, constant: -16),
            attachmentsStackView.bottomAnchor.constraint(equalTo: attachmentContainerView.bottomAnchor, constant: -16),
            attachmentContainerHeightConstraint
        ])
        contentStackView.addArrangedSubview(attachmentContainerView)

        // Submit To Card
        submitToContainerView.translatesAutoresizingMaskIntoConstraints = false
        submitToTitleLabel.text = "Submit To"
        
        submitToButton.translatesAutoresizingMaskIntoConstraints = false
        submitToButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        submitToButton.tintColor = AppTheme.buttonColor
        submitToButton.contentHorizontalAlignment = .right
        submitToButton.semanticContentAttribute = .forceRightToLeft
        submitToButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)

        let submitToRow = UIStackView(arrangedSubviews: [submitToTitleLabel, UIView(), submitToButton])
        submitToRow.translatesAutoresizingMaskIntoConstraints = false
        submitToRow.axis = .horizontal
        submitToRow.spacing = 12
        submitToRow.alignment = .center
        
        submitToContainerView.addSubview(submitToRow)
        
        NSLayoutConstraint.activate([
            submitToRow.topAnchor.constraint(equalTo: submitToContainerView.topAnchor, constant: 14),
            submitToRow.leadingAnchor.constraint(equalTo: submitToContainerView.leadingAnchor, constant: 16),
            submitToRow.trailingAnchor.constraint(equalTo: submitToContainerView.trailingAnchor, constant: -16),
            submitToRow.bottomAnchor.constraint(equalTo: submitToContainerView.bottomAnchor, constant: -14),
            submitToContainerView.heightAnchor.constraint(equalToConstant: 56)
        ])
        contentStackView.addArrangedSubview(submitToContainerView)

        // Submit Button
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.setTitle("Submit for review", for: .normal)
        submitButton.backgroundColor = AppTheme.buttonColor
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = 20
        submitButton.addTarget(self, action: #selector(submitButtonTapped), for: .touchUpInside)
        
        let submitButtonContainer = UIView()
        submitButtonContainer.backgroundColor = .clear
        submitButtonContainer.addSubview(submitButton)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            submitButton.topAnchor.constraint(equalTo: submitButtonContainer.topAnchor, constant: 10),
            submitButton.centerXAnchor.constraint(equalTo: submitButtonContainer.centerXAnchor),
            submitButton.widthAnchor.constraint(equalTo: submitButtonContainer.widthAnchor, multiplier: 0.8),
            submitButton.heightAnchor.constraint(equalToConstant: 50),
            submitButton.bottomAnchor.constraint(equalTo: submitButtonContainer.bottomAnchor, constant: -20)
        ])
        contentStackView.addArrangedSubview(submitButtonContainer)
    }

    private func applyConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }

    private func setupUI() {
        AppTheme.applyScreenBackground(to: view)
        setupRefreshControl()
        taskTitleLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        dueDateLabel.font   = UIFont.systemFont(ofSize: 16)
        dueDateLabel.textColor = .secondaryLabel
        submitButton.titleLabel?.font   = .systemFont(ofSize: 17, weight: .semibold)
        view.layoutIfNeeded()
        applyTheme()
    }
    
    private func setupRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        scrollView.refreshControl = refreshControl
    }

    private func setupLoadingIndicator() {
        let overlay = UIView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.16)
        overlay.isHidden = true
        overlay.alpha = 0
        view.addSubview(overlay)

        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        indicator.color = .white
        overlay.addSubview(indicator)

        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            indicator.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
        ])

        loadingOverlayView = overlay
        loadingIndicator = indicator
    }

    @MainActor
    private func setLoading(_ isLoading: Bool, showOverlay: Bool = true) {
        if isLoading {
            if showOverlay {
                loadingOverlayView?.isHidden = false
                loadingIndicator?.startAnimating()
                UIView.animate(withDuration: 0.18) {
                    self.loadingOverlayView?.alpha = 1
                }
            }
        } else {
            scrollView.refreshControl?.endRefreshing()
            guard showOverlay else { return }
            UIView.animate(withDuration: 0.18, animations: {
                self.loadingOverlayView?.alpha = 0
            }, completion: { _ in
                self.loadingIndicator?.stopAnimating()
                self.loadingOverlayView?.isHidden = true
            })
        }
    }
    
    @objc private func handleRefresh() {
        Task { await loadSupabaseData(showOverlayLoader: false) }
    }

    // MARK: - Configure with DashboardTask

    func configure(with task: DashboardTask) {
        self.task = task
        guard isViewLoaded else { return }

        taskTitleLabel.text    = task.title
        dueDateLabel.text      = task.dueDate
        assigneeNameLabel.text = task.assigneeName
        assigneeImageView.image = task.assigneeImage ?? placeholderImage(for: task.assigneeName)
        mentorFeedbackText = task.remark
        applySubmissionState(for: task.status, showAlert: false)

        resourcesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        resourcesContainerView.isHidden = false
        let hasFeedback = !(task.remark?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        if hasFeedback {
            addMentorFeedbackRow(task.remark ?? "")
        }
        if task.attachmentNames.isEmpty {
            showNoResourcesLabel()
        } else {
            removeNoResourcesLabel()
            for file in task.attachmentNames { addResourceRow(filename: file) }
        }
        updateResourcesContainerHeight()
        updateAttachmentContainerHeight()
    }

    // MARK: - Load Supabase data

    private func loadSupabaseData(showOverlayLoader: Bool = true) async {
        guard let task = task else { return }
        await MainActor.run { self.setLoading(true, showOverlay: showOverlayLoader) }
        
        async let mentorName    = fetchMentorName(task: task)
        async let assigneeName  = fetchAssigneeName(task: task)
        async let mentors       = fetchAllMentors()
        async let attachments   = fetchAttachments(task: task)
        async let currentTaskRow = fetchCurrentTaskRow(task: task)

        let (mentor, assignee, allMentors, fetchedAttachments, latestTask) =
            await (mentorName, assigneeName, mentors, attachments, currentTaskRow)

        await MainActor.run {
            if let latestTask {
                self.task?.status = latestTask.status
                self.task?.remark = latestTask.remark
                self.mentorFeedbackText = latestTask.remark
            }

            assignedByNameLabel.text = mentor
            assigneeNameLabel.text   = assignee
            assigneeImageView.image  = placeholderImage(for: assignee)

            self.mentorOptions = allMentors
            let actions = allMentors.map { m in
                UIAction(title: m.name) { [weak self] _ in
                    self?.selectedSubmitTo = m.personId
                    self?.submitToButton.setTitle(m.name, for: .normal)
                }
            }
            if !actions.isEmpty {
                submitToButton.menu = UIMenu(children: actions)
                submitToButton.showsMenuAsPrimaryAction = true
                submitToButton.setTitle(actions[0].title, for: .normal)
                selectedSubmitTo = allMentors[0].personId
            }

            // Resources section — existing files (read-only display)
            self.resourcesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            self.resourcesContainerView.isHidden = false

            if let feedback = self.mentorFeedbackText?.trimmingCharacters(in: .whitespacesAndNewlines),
               !feedback.isEmpty {
                self.addMentorFeedbackRow(feedback)
            }
            
            // Filter only mentor attachments for the resources section
            let mentorResources = fetchedAttachments.filter { row in
                row.mentor_attachment == true || (row.mentor_attachment == nil && row.student_id == nil)
            }
            self.fetchedMentorAttachments = mentorResources
            
            if mentorResources.isEmpty {
                self.showNoResourcesLabel()
            } else {
                self.removeNoResourcesLabel()
                for resource in mentorResources { self.addResourceRow(filename: resource.filename) }
            }
            self.updateResourcesContainerHeight()
            self.applySubmissionState(for: self.task?.status, showAlert: false)

            // Filter student attachments for the submission section
            let studentAttachments = fetchedAttachments.filter { row in
                row.mentor_attachment == false || (row.mentor_attachment == nil && row.student_id != nil)
            }
            self.fetchedStudentAttachments = studentAttachments
            
            // Clear existing rows before adding
            self.attachmentsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            if !studentAttachments.isEmpty {
                for att in studentAttachments {
                    self.addAttachmentRow(filename: att.filename, canDelete: false)
                }
            }
            self.updateAttachmentContainerHeight()
            self.setLoading(false, showOverlay: showOverlayLoader)
        }
    }
    
    /// Stored attachments so they can be decoded from base64 when tapped
    private var fetchedMentorAttachments: [SupabaseManager.TaskAttachmentRow] = []
    private var fetchedStudentAttachments: [SupabaseManager.TaskAttachmentRow] = []

    // MARK: - No-resources empty state

    private let noResourcesTag = 99_001

    private func showNoResourcesLabel() {
        guard resourcesStackView.viewWithTag(noResourcesTag) == nil else { return }
        let label           = UILabel()
        label.tag           = noResourcesTag
        label.text          = "No resources attached"
        let isDark = traitCollection.userInterfaceStyle == .dark
        let bgColor = isDark ? UIColor(white: 0.22, alpha: 1) : UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1)
        let fgColor = isDark ? UIColor.lightGray : UIColor.systemGray
        
        label.backgroundColor = bgColor
        label.layer.cornerRadius = rowCornerRadius
        label.clipsToBounds = true
        label.textColor = fgColor
        label.font          = UIFont.systemFont(ofSize: 15)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.heightAnchor.constraint(equalToConstant: 40).isActive = true
        resourcesStackView.addArrangedSubview(label)
        resourcesContainerView.isHidden = false
        resourcesContainerHeightConstraint.constant = 92
    }

    private func removeNoResourcesLabel() {
        if let v = resourcesStackView.viewWithTag(noResourcesTag) {
            resourcesStackView.removeArrangedSubview(v); v.removeFromSuperview()
        }
    }

    private func updateResourcesContainerHeight() {
        resourcesStackView.layoutIfNeeded()
        let stackHeight = resourcesStackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        let contentHeight = max(40, stackHeight)
        resourcesContainerView.isHidden = resourcesStackView.arrangedSubviews.isEmpty
        resourcesContainerHeightConstraint.constant = 44 + 16 + 12 + contentHeight + 16
        UIView.animate(withDuration: 0.3) { self.view.layoutIfNeeded() }
    }

    // MARK: - Supabase fetch helpers

    private func fetchMentorName(task: DashboardTask) async -> String {
        if let teamId = task.teamId {
            do {
                struct TeamMentorRow: Decodable { let mentor_name: String?; let mentor_id: String? }
                let rows: [TeamMentorRow] = try await SupabaseManager.shared.client
                    .from("new_teams").select("mentor_name, mentor_id")
                    .eq("id", value: teamId).limit(1).execute().value
                if let name = rows.first?.mentor_name, !name.isEmpty { return name }
                if let mid = rows.first?.mentor_id ?? task.mentorId {
                    return (try? await SupabaseManager.shared.fetchMentorFullName(personId: mid)) ?? "Mentor"
                }
            } catch { print("❌ fetchMentorName:", error) }
        }
        if let mid = task.mentorId {
            return (try? await SupabaseManager.shared.fetchMentorFullName(personId: mid)) ?? "Mentor"
        }
        return "Mentor"
    }

    private func fetchAssigneeName(task: DashboardTask) async -> String {
        guard let taskId = task.taskId, let teamId = task.teamId else { return task.assigneeName }
        return (try? await SupabaseManager.shared.resolveAssigneeNameFromNewTeams(
            taskId: taskId, teamId: teamId)) ?? task.assigneeName
    }

    private func fetchAllMentors() async -> [(name: String, personId: String)] {
        struct MentorRow: Decodable { let person_id: String; let first_name: String?; let last_name: String? }
        guard let rows = try? await SupabaseManager.shared.client
            .from("mentor_profiles").select("person_id, first_name, last_name")
            .execute().value as [MentorRow] else { return [] }
        return rows.compactMap {
            let full = "\($0.first_name ?? "") \($0.last_name ?? "")".trimmingCharacters(in: .whitespaces)
            return full.isEmpty ? nil : (name: full, personId: $0.person_id)
        }
    }

    private func fetchAttachments(task: DashboardTask) async -> [SupabaseManager.TaskAttachmentRow] {
        guard let taskId = task.taskId else { return [] }
        return (try? await SupabaseManager.shared.fetchTaskAttachments(taskId: taskId)) ?? []
    }

    private func fetchCurrentTaskRow(task: DashboardTask) async -> SupabaseManager.TaskRow? {
        guard let taskId = task.taskId else { return nil }
        return try? await SupabaseManager.shared.fetchTask(taskId: taskId)
    }

    // MARK: - Attachment row UI
    
    /// Adds a display row in the Resources stack for mentor-attached items
    private func addResourceRow(filename: String) {
        let isDark = traitCollection.userInterfaceStyle == .dark
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = isDark
            ? UIColor(white: 0.22, alpha: 1)
            : UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1)
        container.layer.cornerRadius = 10
        
        let isLink = filename.hasPrefix("http://") || filename.hasPrefix("https://")
        let ext = (filename as NSString).pathExtension.lowercased()
        let iconName: String = {
            if isLink { return "link" }
            switch ext {
            case "pdf":                     return "doc.text.fill"
            case "jpg","jpeg","png","heic": return "photo.fill"
            case "doc","docx":              return "doc.text.fill"
            default:                        return "doc.fill"
            }
        }()
        
        let icon = UIImageView(image: UIImage(systemName: iconName))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFit
        icon.tintColor = AppTheme.buttonColor
        
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text = isLink ? (URL(string: filename)?.host ?? filename) : filename
        lbl.font = UIFont.systemFont(ofSize: 15)
        lbl.textColor = isLink ? AppTheme.buttonColor : .label
        lbl.numberOfLines = 1
        
        container.addSubview(icon)
        container.addSubview(lbl)
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 40),
            icon.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            icon.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24),
            lbl.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),
            lbl.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            lbl.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(resourceTapped(_:)))
        container.addGestureRecognizer(tapGesture)
        container.isUserInteractionEnabled = true
        container.accessibilityIdentifier = filename
        
        resourcesStackView.addArrangedSubview(container)
    }

    private func addMentorFeedbackRow(_ feedback: String) {
        let box = UIView()
        box.translatesAutoresizingMaskIntoConstraints = false
        box.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.10)
        box.layer.cornerRadius = 14
        box.layer.borderWidth = 1
        box.layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.25).cgColor

        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = "Mentor Feedback"
        title.font = .systemFont(ofSize: 15, weight: .semibold)
        title.textColor = .systemOrange

        let body = UILabel()
        body.translatesAutoresizingMaskIntoConstraints = false
        body.text = feedback
        body.font = .systemFont(ofSize: 14)
        body.textColor = .label
        body.numberOfLines = 0

        box.addSubview(title)
        box.addSubview(body)

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: box.topAnchor, constant: 12),
            title.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 12),
            title.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -12),

            body.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 6),
            body.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 12),
            body.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -12),
            body.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -12),
            box.heightAnchor.constraint(greaterThanOrEqualToConstant: 86)
        ])

        resourcesStackView.addArrangedSubview(box)
    }

    private func applySubmissionState(for status: String?, showAlert: Bool) {
        let normalizedStatus = status?.lowercased() ?? ""

        switch normalizedStatus {
        case "for_review":
            setSubmittedState(shouldAlert: showAlert)
        default:
            setEditableState()
        }
    }

    private func setSubmittedState(shouldAlert: Bool) {
        isSubmitted = true
        pendingAttachments.removeAll()
        submitButton.setTitle("Redo Submission", for: .normal)
        submitButton.backgroundColor = .systemOrange
        submitButton.isEnabled = true
        attachmentIconButton.isEnabled = false
        attachmentIconButton.alpha = 0.5

        attachmentsStackView.arrangedSubviews.forEach { container in
            container.subviews.compactMap { $0 as? UIButton }.forEach { btn in
                btn.alpha = 0
                btn.isHidden = true
            }
        }

        if shouldAlert {
            showAlert(title: "Submitted",
                      message: "Your task has been sent to the mentor for review.")
        }
    }

    private func setEditableState() {
        isSubmitted = false
        submitButton.setTitle("Submit for review", for: .normal)
        submitButton.backgroundColor = AppTheme.buttonColor
        submitButton.isEnabled = true
        attachmentIconButton.isEnabled = true
        attachmentIconButton.alpha = 1.0
    }
    
    @objc private func resourceTapped(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view, let filename = view.accessibilityIdentifier else { return }
        
        let isLink = filename.hasPrefix("http://") || filename.hasPrefix("https://")
        if isLink, let url = URL(string: filename) {
            let safari = SFSafariViewController(url: url)
            safari.modalPresentationStyle = .pageSheet
            present(safari, animated: true)
            return
        }
        
        // Try to decode image to present in full screen
        if let attachmentRow = fetchedMentorAttachments.first(where: { $0.filename == filename }),
           let base64 = attachmentRow.file_data,
           let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters),
           let image = UIImage(data: data) {
            
            let viewer = AttachmentViewerViewController(attachments: [image], attachmentFilenames: [filename])
            viewer.modalPresentationStyle = UIModalPresentationStyle.fullScreen
            present(viewer, animated: true)
            return
        }
        
        // Base case: Show alert with filename for unsupported formats or missing data
        let a = UIAlertController(title: "Attachment", message: filename, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    /// Adds a display row in the stack. `canDelete` controls whether the × button shows.
    private func addAttachmentRow(filename: String, canDelete: Bool) {
        let isDark = traitCollection.userInterfaceStyle == .dark
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = isDark
            ? UIColor(white: 0.22, alpha: 1)
            : UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1)
        container.layer.cornerRadius = 12

        let isLink   = filename.hasPrefix("http://") || filename.hasPrefix("https://")
        let ext      = (filename as NSString).pathExtension.lowercased()
        let iconName: String = {
            if isLink { return "link" }
            switch ext {
            case "pdf":                     return "doc.text.fill"
            case "jpg","jpeg","png","heic": return "photo.fill"
            case "doc","docx":              return "doc.text.fill"
            default:                        return "doc.fill"
            }
        }()

        let icon = UIImageView(image: UIImage(systemName: iconName))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFit
        icon.tintColor   = AppTheme.buttonColor

        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text          = isLink ? (URL(string: filename)?.host ?? filename) : filename
        lbl.font          = UIFont.systemFont(ofSize: 16)
        lbl.textColor     = isLink ? AppTheme.buttonColor : .label
        lbl.numberOfLines = 1

        let delBtn = UIButton(type: .system)
        delBtn.translatesAutoresizingMaskIntoConstraints = false
        delBtn.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        delBtn.tintColor = .systemRed
        delBtn.isHidden  = !canDelete
        delBtn.addTarget(self, action: #selector(deleteAttachmentRow(_:)), for: .touchUpInside)

        container.addSubview(icon); container.addSubview(lbl); container.addSubview(delBtn)
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 50),
            icon.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            icon.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 28),
            icon.heightAnchor.constraint(equalToConstant: 28),
            lbl.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            lbl.trailingAnchor.constraint(equalTo: delBtn.leadingAnchor, constant: -8),
            lbl.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            delBtn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            delBtn.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            delBtn.widthAnchor.constraint(equalToConstant: 24),
            delBtn.heightAnchor.constraint(equalToConstant: 24)
        ])

        // Tag the container with the pendingAttachments index so delete can find it
        container.tag = pendingAttachments.count  // meaningful only for pending rows
        container.accessibilityIdentifier = filename // Store filename to access on tap

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(studentAttachmentTapped(_:)))
        container.addGestureRecognizer(tapGesture)
        container.isUserInteractionEnabled = true

        attachmentsStackView.addArrangedSubview(container)
        updateAttachmentContainerHeight()
    }

    @objc private func studentAttachmentTapped(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view, let filename = view.accessibilityIdentifier else { return }
        
        let isLink = filename.hasPrefix("http://") || filename.hasPrefix("https://")
        if isLink, let url = URL(string: filename) {
            let safari = SFSafariViewController(url: url)
            safari.modalPresentationStyle = .pageSheet
            present(safari, animated: true)
            return
        }
        
        // Try to decode image to present in full screen
        // First check pending attachments
        if let pending = pendingAttachments.first(where: { $0.filename == filename }),
           let data = Data(base64Encoded: pending.base64Data, options: .ignoreUnknownCharacters),
           let image = UIImage(data: data) {
            let viewer = AttachmentViewerViewController(attachments: [image], attachmentFilenames: [filename])
            viewer.modalPresentationStyle = UIModalPresentationStyle.fullScreen
            present(viewer, animated: true)
            return
        }
        
        // Then check fetched student attachments
        if let attachmentRow = fetchedStudentAttachments.first(where: { $0.filename == filename }),
           let base64 = attachmentRow.file_data,
           let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters),
           let image = UIImage(data: data) {
            let viewer = AttachmentViewerViewController(attachments: [image], attachmentFilenames: [filename])
            viewer.modalPresentationStyle = UIModalPresentationStyle.fullScreen
            present(viewer, animated: true)
            return
        }
        
        // Base case: Show alert with filename for unsupported formats or missing data
        let a = UIAlertController(title: "Attachment", message: filename, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    @objc private func deleteAttachmentRow(_ sender: UIButton) {
        guard let container = sender.superview else { return }

        // Find which pending attachment this row corresponds to by matching the tag
        let rowTag = container.tag
        if rowTag < pendingAttachments.count {
            pendingAttachments.remove(at: rowTag)
            // Re-tag remaining rows
            for (i, view) in attachmentsStackView.arrangedSubviews.enumerated() {
                view.tag = i
            }
        }

        UIView.animate(withDuration: 0.25, animations: { container.alpha = 0 }) { _ in
            self.attachmentsStackView.removeArrangedSubview(container)
            container.removeFromSuperview()
            self.updateAttachmentContainerHeight()
        }
    }

    private func updateAttachmentContainerHeight() {
        view.layoutIfNeeded()
        attachmentsStackView.layoutIfNeeded()
        let fittingWidth = max(attachmentsStackView.bounds.width, view.bounds.width - 64)
        let targetSize = CGSize(width: fittingWidth, height: UIView.layoutFittingCompressedSize.height)
        let stackHeight = attachmentsStackView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        let h: CGFloat = 16 + 30 + 12 + max(0, stackHeight) + 16
        attachmentContainerHeightConstraint.constant = h
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            let insetTop = self.scrollView.adjustedContentInset.top
            let insetBottom = self.scrollView.adjustedContentInset.bottom
            let maxOffsetY = max(
                -insetTop,
                self.scrollView.contentSize.height - self.scrollView.bounds.height + insetBottom
            )
            if self.scrollView.contentOffset.y > maxOffsetY {
                self.scrollView.setContentOffset(CGPoint(x: self.scrollView.contentOffset.x, y: maxOffsetY), animated: false)
            }
        }
    }

    // MARK: - Placeholder image

    private func placeholderImage(for name: String) -> UIImage {
        let size = CGSize(width: 40, height: 40)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let ctx = UIGraphicsGetCurrentContext()!
        AppTheme.buttonColor.setFill(); ctx.fillEllipse(in: CGRect(origin: .zero, size: size))
        let initial = String(name.prefix(1)).uppercased()
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18), .foregroundColor: UIColor.white
        ]
        let t = initial.size(withAttributes: attrs)
        initial.draw(in: CGRect(x: (size.width-t.width)/2, y: (size.height-t.height)/2,
                                width: t.width, height: t.height), withAttributes: attrs)
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return img
    }

    // MARK: - Attachment picker

    @IBAction func attachmentButtonTapped(_ sender: UIButton) {
        guard !isSubmitted else {
            showAlert(title: "Already Submitted", message: "Use 'Redo Submission' to modify attachments.")
            return
        }
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let cam = UIAlertAction(title: "Camera", style: .default) { _ in self.openCamera() }
        cam.setValue(UIImage(systemName: "camera.fill")?.withTintColor(AppTheme.buttonColor, renderingMode: .alwaysOriginal), forKey: "image")
        sheet.addAction(cam)

        let gal = UIAlertAction(title: "Photo Library", style: .default) { _ in self.openPhotoLibrary() }
        gal.setValue(UIImage(systemName: "photo.fill")?.withTintColor(AppTheme.buttonColor, renderingMode: .alwaysOriginal), forKey: "image")
        sheet.addAction(gal)

        let doc = UIAlertAction(title: "Documents", style: .default) { _ in self.openDocumentPicker() }
        doc.setValue(UIImage(systemName: "doc.fill")?.withTintColor(AppTheme.buttonColor, renderingMode: .alwaysOriginal), forKey: "image")
        sheet.addAction(doc)

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = sheet.popoverPresentationController { pop.sourceView = sender; pop.sourceRect = sender.bounds }
        present(sheet, animated: true)
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAlert(title: "Unavailable", message: "Camera not available."); return
        }
        let p = UIImagePickerController(); p.sourceType = .camera; p.delegate = self
        present(p, animated: true)
    }

    private func openPhotoLibrary() {
        let p = UIImagePickerController(); p.sourceType = .photoLibrary; p.delegate = self
        present(p, animated: true)
    }

    private func openDocumentPicker() {
        let p = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .text, .data])
        p.delegate = self; p.allowsMultipleSelection = false
        present(p, animated: true)
    }

    // MARK: - Submit

    @IBAction func submitButtonTapped(_ sender: UIButton) {
        if isSubmitted {
            let a = UIAlertController(title: "Redo Submission",
                                      message: "Allow modifying and resubmitting?",
                                      preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            a.addAction(UIAlertAction(title: "Redo", style: .destructive) { _ in self.redoSubmissionInSupabase() })
            present(a, animated: true)
        } else {
            submitButton.isEnabled = false
            submitButton.setTitle("Submitting...", for: .normal)
            setLoading(true, showOverlay: true)
            submitTaskToSupabase()
        }
    }

    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension TaskDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.originalImage] as? UIImage,
              let jpegData = image.jpegData(compressionQuality: 0.75) else { return }

        let base64Str = jpegData.base64EncodedString()
        let filename  = picker.sourceType == .camera
            ? "Camera_\(Int(Date().timeIntervalSince1970)).jpeg"
            : "Photo_\(Int(Date().timeIntervalSince1970)).jpeg"

        let payload = AttachmentPayload(filename: filename, fileType: "image/jpeg",
                                        base64Data: base64Str, isLink: false)

        let idx = pendingAttachments.count
        pendingAttachments.append(payload)

        // Tag the newly added row with its index so delete works
        addAttachmentRow(filename: filename, canDelete: true)
        attachmentsStackView.arrangedSubviews.last?.tag = idx
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate

extension TaskDetailViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController,
                        didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }

        // Read raw bytes and base64-encode
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let data = try? Data(contentsOf: url) else {
            showAlert(title: "Error", message: "Could not read file."); return
        }

        let base64Str = data.base64EncodedString()
        let filename  = url.lastPathComponent
        let ext       = url.pathExtension.lowercased()
        let mimeType: String = {
            switch ext {
            case "pdf":        return "application/pdf"
            case "doc","docx": return "application/msword"
            case "txt":        return "text/plain"
            default:           return "application/octet-stream"
            }
        }()

        let payload = AttachmentPayload(filename: filename, fileType: mimeType,
                                        base64Data: base64Str, isLink: false)

        let idx = pendingAttachments.count
        pendingAttachments.append(payload)

        addAttachmentRow(filename: filename, canDelete: true)
        attachmentsStackView.arrangedSubviews.last?.tag = idx
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
    }
}

// MARK: - Supabase Submit / Redo

extension TaskDetailViewController {

    // MARK: Submit for review

    func submitTaskToSupabase() {
        guard let task, let taskId = task.taskId else {
            showAlert(title: "Error", message: "Task information is missing."); return
        }

        guard !pendingAttachments.isEmpty else {
            // Allow submission with no new files — just update status
            updateTaskStatusOnly(taskId: taskId, to: "for_review"); return
        }

        Task {
            do {
                let studentId = UserDefaults.standard.string(forKey: "current_person_id") ?? ""
                let teamIdStr = task.teamId ?? ""

                // ── INSERT each attachment (plain insert, no upsert) ──────────
                for attachment in pendingAttachments {

                    struct AttachmentInsert: Encodable {
                        let task_id:           String
                        let filename:          String
                        let file_type:         String
                        let file_data:         String?   // base64
                        let student_id:        String?
                        let team_id:           String?
                        let mentor_attachment: Bool
                    }

                    let row = AttachmentInsert(
                        task_id:           taskId,
                        filename:          attachment.filename,
                        file_type:         attachment.fileType,
                        file_data:         attachment.base64Data.isEmpty ? nil : attachment.base64Data,
                        student_id:        studentId.isEmpty ? nil : studentId,
                        team_id:           nil, // Bypassing FK error since tasks are tied to new_teams, while task_attachments FK points to old teams table.
                        mentor_attachment: false
                    )

                    try await SupabaseManager.shared.client
                        .from("task_attachments")
                        .insert(row)           // ← plain INSERT, no conflict clause
                        .execute()
                }

                // ── Update task status ────────────────────────────────────────
                try await updateStatusRow(taskId: taskId, status: "for_review")

                // Sync counters for mentor dashboard
                try? await SupabaseManager.shared.recalculateAndSyncTeamTaskCounters(teamId: teamIdStr)

                await MainActor.run {
                    self.setLoading(false, showOverlay: true)
                    self.markSubmitted()
                }

            } catch {
                await MainActor.run {
                    self.setLoading(false, showOverlay: true)
                    self.setEditableState()
                    self.showAlert(title: "Submission Failed", message: error.localizedDescription)
                }
            }
        }
    }

    /// Update status only (no attachments)
    private func updateTaskStatusOnly(taskId: String, to status: String) {
        let teamIdStr = task?.teamId ?? ""
        Task {
            do {
                try await updateStatusRow(taskId: taskId, status: status)
                
                // Sync counters for mentor dashboard
                if !teamIdStr.isEmpty {
                    try? await SupabaseManager.shared.recalculateAndSyncTeamTaskCounters(teamId: teamIdStr)
                }
                
                await MainActor.run {
                    self.setLoading(false, showOverlay: true)
                    if status == "for_review" { self.markSubmitted() }
                }
            } catch {
                await MainActor.run {
                    self.setLoading(false, showOverlay: true)
                    self.setEditableState()
                    self.showAlert(title: "Submission Failed", message: error.localizedDescription)
                }
            }
        }
    }

    private func updateStatusRow(taskId: String, status: String) async throws {
        struct StatusUpdate: Encodable { let status: String; let updated_at: String }
        try await SupabaseManager.shared.client
            .from("tasks")
            .update(StatusUpdate(status: status,
                                 updated_at: ISO8601DateFormatter().string(from: Date())))
            .eq("id", value: taskId)
            .execute()
    }

    private func markSubmitted() {
        task?.status = "for_review"
        setSubmittedState(shouldAlert: true)
    }

    // MARK: Redo submission

    func redoSubmissionInSupabase() {
        guard let task, let taskId = task.taskId else { return }

        Task {
            do {
                try await updateStatusRow(taskId: taskId, status: "ongoing")
                
                // Sync counters for mentor dashboard
                if let teamId = task.teamId {
                    try? await SupabaseManager.shared.recalculateAndSyncTeamTaskCounters(teamId: teamId)
                }

                await MainActor.run {
                    self.task?.status = "ongoing"
                    self.setEditableState()

                    attachmentsStackView.arrangedSubviews.forEach { container in
                        container.subviews.compactMap { $0 as? UIButton }.forEach { btn in
                            btn.isHidden = false
                            UIView.animate(withDuration: 0.3) { btn.alpha = 1 }
                        }
                    }

                    showAlert(title: "Ready to Edit",
                              message: "You can now modify attachments and resubmit.")
                }
            } catch {
                await MainActor.run {
                    showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
}
