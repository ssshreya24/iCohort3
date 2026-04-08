//
//  ReviewViewController.swift
//  iCohort3
//
//  Fully programmatic — no XIB. Rebuilt to eliminate XIB override issues.

import UIKit
import SafariServices
import Supabase
import PostgREST

// MARK: - Delegate
protocol ReviewViewControllerDelegate: AnyObject {
    func reviewViewController(_ vc: ReviewViewController,
                              didChangeStatusTo status: String,
                              forTaskId taskId: String)
}

class ReviewViewController: UIViewController, UITextViewDelegate {

    // MARK: - Public (set before presenting)
    var teamId:    String = ""
    var teamNo:    Int    = 0
    var taskId:    String = ""
    var taskTitle: String?
    var teamName:  String?

    weak var delegate: ReviewViewControllerDelegate?

    // MARK: - Private state
    private let remarkPlaceholder    = "Add remark"
    private var firstAttachmentName: String?
    private var fetchedAttachments: [SupabaseManager.TaskAttachmentRow] = []
    private var isUpdating           = false

    // MARK: - UI Elements (programmatic)

    // Navigation
    private lazy var backButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private lazy var titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Review"
        lbl.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = true
        sv.alwaysBounceVertical = true
        sv.backgroundColor = .clear
        return sv
    }()

    private lazy var contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .clear
        return v
    }()

    // Title Card
    private lazy var titleCardView: UIView = makeCard()

    private lazy var pencilImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "pencil"))
        iv.tintColor = .systemGray
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private lazy var taskTitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        lbl.numberOfLines = 0
        lbl.lineBreakMode = .byWordWrapping
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private lazy var titleSeparator: UIView = makeSeparator()

    private lazy var calendarImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "calendar"))
        iv.tintColor = .systemRed
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private lazy var dueDateStaticLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Due Date"
        lbl.font = UIFont.systemFont(ofSize: 17)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private lazy var dueDateValueLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "—"
        lbl.font = UIFont.systemFont(ofSize: 17)
        lbl.textAlignment = .right
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // Attachment Card
    private lazy var attachmentCardView: UIView = makeCard()

    private lazy var attachmentStaticLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Attachment"
        lbl.font = UIFont.systemFont(ofSize: 17)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private lazy var paperclipImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "paperclip"))
        iv.tintColor = .systemGray
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private lazy var attachmentSeparator: UIView = makeSeparator()

    // Row that shows the attachment (icon + filename)
    private lazy var attachmentRowView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.systemGray6
        v.layer.cornerRadius = 12
        v.layer.masksToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var attachmentTypeIconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private lazy var attachmentIconBackground: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBlue
        v.layer.cornerRadius = 8
        v.layer.masksToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var attachmentFileNameButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.contentHorizontalAlignment = .leading
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        btn.titleLabel?.lineBreakMode = .byTruncatingMiddle
        btn.addTarget(self, action: #selector(attachmentButtonTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // Remark Card
    private lazy var descriptionCardView: UIView = {
        let v = makeCard()
        return v
    }()

    private lazy var remarkTextView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.backgroundColor = .clear
        tv.layer.cornerRadius = 14
        tv.layer.masksToBounds = true
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    // Assigned To Card
    private lazy var assignedToCardView: UIView = makeCard()

    private lazy var assignedToStaticLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Assigned To"
        lbl.font = UIFont.systemFont(ofSize: 17)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private lazy var personImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "person.circle.fill"))
        iv.tintColor = .systemGray
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private lazy var assigneeNameLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 17)
        lbl.numberOfLines = 1
        lbl.adjustsFontSizeToFitWidth = true
        lbl.minimumScaleFactor = 0.7
        lbl.lineBreakMode = .byTruncatingTail
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // Status Card
    private lazy var statusCardView: UIView = makeCard()

    private lazy var statusStaticLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Status"
        lbl.font = UIFont.systemFont(ofSize: 17)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private lazy var statusValueLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 17)
        lbl.textAlignment = .right
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // Action Buttons
    private lazy var rejectButton: UIButton = {
        let btn = UIButton(type: .system)
        var cfg = UIButton.Configuration.gray()
        cfg.title = "Reject"
        cfg.baseForegroundColor = .systemRed
        cfg.baseBackgroundColor = .white
        btn.configuration = cfg
        btn.addTarget(self, action: #selector(rejectButtonTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private lazy var completeButton: UIButton = {
        let btn = UIButton(type: .system)
        var cfg = UIButton.Configuration.gray()
        cfg.title = "Approve"
        cfg.baseForegroundColor = .systemGreen
        cfg.baseBackgroundColor = .white
        btn.configuration = cfg
        btn.addTarget(self, action: #selector(completeButtonTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        enableKeyboardDismissOnTap()
        AppTheme.applyScreenBackground(to: view)
        buildLayout()
        setupRemarkTextView()
        setupRefreshControl()

        // Placeholder states
        taskTitleLabel.text    = taskTitle ?? "Loading…"
        assigneeNameLabel.text = "Loading…"
        dueDateValueLabel.text = "—"
        attachmentFileNameButton.setTitle("Loading…", for: .normal)
        attachmentFileNameButton.setTitleColor(.systemGray3, for: .normal)
        attachmentFileNameButton.isEnabled = false
        applyStatusUI(for: "for_review")

        scrollView.backgroundColor = .clear
        contentView.backgroundColor = .clear

        Task { await loadFromSupabase() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        AppTheme.applyScreenBackground(to: view)
        styleBackButton()
        styleActionButtons()
        applyThemeFontsAndColors()
    }

    @available(iOS, deprecated: 17.0, message: "Use registerForTraitChanges")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            AppTheme.applyScreenBackground(to: view)
            styleBackButton()
            styleActionButtons()
            applyThemeFontsAndColors()
            styleCards()
        }
    }

    // MARK: - Layout

    private func buildLayout() {
        // Add scroll hierarchy
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // ── Navigation header ──────────────────────────────────────────────
        contentView.addSubview(backButton)
        contentView.addSubview(titleLabel)

        // ── Title Card ─────────────────────────────────────────────────────
        titleCardView.addSubview(pencilImageView)
        titleCardView.addSubview(taskTitleLabel)
        titleCardView.addSubview(titleSeparator)
        titleCardView.addSubview(calendarImageView)
        titleCardView.addSubview(dueDateStaticLabel)
        titleCardView.addSubview(dueDateValueLabel)
        contentView.addSubview(titleCardView)

        // ── Attachment Card ────────────────────────────────────────────────
        attachmentCardView.addSubview(attachmentStaticLabel)
        attachmentCardView.addSubview(paperclipImageView)
        attachmentCardView.addSubview(attachmentSeparator)
        attachmentCardView.addSubview(attachmentRowView)
        attachmentIconBackground.addSubview(attachmentTypeIconView)
        attachmentRowView.addSubview(attachmentIconBackground)
        attachmentRowView.addSubview(attachmentFileNameButton)
        contentView.addSubview(attachmentCardView)

        // ── Remark Card ────────────────────────────────────────────────────
        descriptionCardView.addSubview(remarkTextView)
        contentView.addSubview(descriptionCardView)

        // ── Assigned To Card ───────────────────────────────────────────────
        assignedToCardView.addSubview(assignedToStaticLabel)
        assignedToCardView.addSubview(personImageView)
        assignedToCardView.addSubview(assigneeNameLabel)
        contentView.addSubview(assignedToCardView)

        // ── Status Card ─────────────────────────────────────────────────────
        statusCardView.addSubview(statusStaticLabel)
        statusCardView.addSubview(statusValueLabel)
        contentView.addSubview(statusCardView)

        // ── Action Buttons ─────────────────────────────────────────────────
        contentView.addSubview(rejectButton)
        contentView.addSubview(completeButton)

        applyConstraints()
        styleCards()
    }

    private func applyConstraints() {
        let margin: CGFloat = 20
        let cardSpacing: CGFloat = 16

        NSLayoutConstraint.activate([

            // ScrollView — fill safe area
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // ContentView — pin to scroll, same width as view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // ── Back button ────────────────────────────────────────────────
            backButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            backButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            // ── Title label ────────────────────────────────────────────────
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            // ── Title Card ─────────────────────────────────────────────────
            titleCardView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 20),
            titleCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            titleCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),

            // pencil icon — top-aligned with label
            pencilImageView.leadingAnchor.constraint(equalTo: titleCardView.leadingAnchor, constant: 12),
            pencilImageView.topAnchor.constraint(equalTo: titleCardView.topAnchor, constant: 16),
            pencilImageView.widthAnchor.constraint(equalToConstant: 22),
            pencilImageView.heightAnchor.constraint(equalToConstant: 22),

            // task title label — top-aligned with pencil, allows multi-line growth
            taskTitleLabel.leadingAnchor.constraint(equalTo: pencilImageView.trailingAnchor, constant: 12),
            taskTitleLabel.trailingAnchor.constraint(equalTo: titleCardView.trailingAnchor, constant: -12),
            taskTitleLabel.topAnchor.constraint(equalTo: titleCardView.topAnchor, constant: 14),

            // separator below label
            titleSeparator.topAnchor.constraint(equalTo: taskTitleLabel.bottomAnchor, constant: 10),
            titleSeparator.leadingAnchor.constraint(equalTo: titleCardView.leadingAnchor, constant: 12),
            titleSeparator.trailingAnchor.constraint(equalTo: titleCardView.trailingAnchor, constant: -12),
            titleSeparator.heightAnchor.constraint(equalToConstant: 1),

            // calendar icon
            calendarImageView.leadingAnchor.constraint(equalTo: titleCardView.leadingAnchor, constant: 12),
            calendarImageView.topAnchor.constraint(equalTo: titleSeparator.bottomAnchor, constant: 12),
            calendarImageView.widthAnchor.constraint(equalToConstant: 26),
            calendarImageView.heightAnchor.constraint(equalToConstant: 26),
            calendarImageView.bottomAnchor.constraint(equalTo: titleCardView.bottomAnchor, constant: -14),

            // due date static label
            dueDateStaticLabel.leadingAnchor.constraint(equalTo: calendarImageView.trailingAnchor, constant: 12),
            dueDateStaticLabel.centerYAnchor.constraint(equalTo: calendarImageView.centerYAnchor),

            // due date value
            dueDateValueLabel.trailingAnchor.constraint(equalTo: titleCardView.trailingAnchor, constant: -16),
            dueDateValueLabel.centerYAnchor.constraint(equalTo: calendarImageView.centerYAnchor),
            dueDateValueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: dueDateStaticLabel.trailingAnchor, constant: 8),

            // ── Attachment Card ────────────────────────────────────────────
            attachmentCardView.topAnchor.constraint(equalTo: titleCardView.bottomAnchor, constant: cardSpacing),
            attachmentCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            attachmentCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),

            // "Attachment" static label
            attachmentStaticLabel.leadingAnchor.constraint(equalTo: attachmentCardView.leadingAnchor, constant: 16),
            attachmentStaticLabel.topAnchor.constraint(equalTo: attachmentCardView.topAnchor, constant: 14),

            // paperclip icon
            paperclipImageView.trailingAnchor.constraint(equalTo: attachmentCardView.trailingAnchor, constant: -16),
            paperclipImageView.centerYAnchor.constraint(equalTo: attachmentStaticLabel.centerYAnchor),
            paperclipImageView.widthAnchor.constraint(equalToConstant: 22),
            paperclipImageView.heightAnchor.constraint(equalToConstant: 22),

            // separator
            attachmentSeparator.topAnchor.constraint(equalTo: attachmentStaticLabel.bottomAnchor, constant: 8),
            attachmentSeparator.leadingAnchor.constraint(equalTo: attachmentCardView.leadingAnchor, constant: 16),
            attachmentSeparator.trailingAnchor.constraint(equalTo: attachmentCardView.trailingAnchor, constant: -16),
            attachmentSeparator.heightAnchor.constraint(equalToConstant: 1),

            // attachment row (icon background + bg row)
            attachmentRowView.topAnchor.constraint(equalTo: attachmentSeparator.bottomAnchor, constant: 10),
            attachmentRowView.leadingAnchor.constraint(equalTo: attachmentCardView.leadingAnchor, constant: 12),
            attachmentRowView.trailingAnchor.constraint(equalTo: attachmentCardView.trailingAnchor, constant: -12),
            attachmentRowView.bottomAnchor.constraint(equalTo: attachmentCardView.bottomAnchor, constant: -12),
            attachmentRowView.heightAnchor.constraint(equalToConstant: 44),

            // icon background box
            attachmentIconBackground.leadingAnchor.constraint(equalTo: attachmentRowView.leadingAnchor, constant: 10),
            attachmentIconBackground.centerYAnchor.constraint(equalTo: attachmentRowView.centerYAnchor),
            attachmentIconBackground.widthAnchor.constraint(equalToConstant: 32),
            attachmentIconBackground.heightAnchor.constraint(equalToConstant: 32),

            // icon inside background
            attachmentTypeIconView.centerXAnchor.constraint(equalTo: attachmentIconBackground.centerXAnchor),
            attachmentTypeIconView.centerYAnchor.constraint(equalTo: attachmentIconBackground.centerYAnchor),
            attachmentTypeIconView.widthAnchor.constraint(equalToConstant: 18),
            attachmentTypeIconView.heightAnchor.constraint(equalToConstant: 18),

            // filename button
            attachmentFileNameButton.leadingAnchor.constraint(equalTo: attachmentIconBackground.trailingAnchor, constant: 10),
            attachmentFileNameButton.trailingAnchor.constraint(equalTo: attachmentRowView.trailingAnchor, constant: -10),
            attachmentFileNameButton.centerYAnchor.constraint(equalTo: attachmentRowView.centerYAnchor),

            // ── Remark Card ────────────────────────────────────────────────
            descriptionCardView.topAnchor.constraint(equalTo: attachmentCardView.bottomAnchor, constant: cardSpacing),
            descriptionCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            descriptionCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),

            remarkTextView.topAnchor.constraint(equalTo: descriptionCardView.topAnchor, constant: 8),
            remarkTextView.leadingAnchor.constraint(equalTo: descriptionCardView.leadingAnchor, constant: 8),
            remarkTextView.trailingAnchor.constraint(equalTo: descriptionCardView.trailingAnchor, constant: -8),
            remarkTextView.bottomAnchor.constraint(equalTo: descriptionCardView.bottomAnchor, constant: -8),
            remarkTextView.heightAnchor.constraint(equalToConstant: 100),

            // ── Assigned To Card ───────────────────────────────────────────
            assignedToCardView.topAnchor.constraint(equalTo: descriptionCardView.bottomAnchor, constant: cardSpacing),
            assignedToCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            assignedToCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            assignedToCardView.heightAnchor.constraint(equalToConstant: 50),

            assignedToStaticLabel.leadingAnchor.constraint(equalTo: assignedToCardView.leadingAnchor, constant: 16),
            assignedToStaticLabel.centerYAnchor.constraint(equalTo: assignedToCardView.centerYAnchor),

            personImageView.widthAnchor.constraint(equalToConstant: 28),
            personImageView.heightAnchor.constraint(equalToConstant: 28),
            personImageView.centerYAnchor.constraint(equalTo: assignedToCardView.centerYAnchor),
            personImageView.trailingAnchor.constraint(equalTo: assigneeNameLabel.leadingAnchor, constant: -8),

            assigneeNameLabel.trailingAnchor.constraint(equalTo: assignedToCardView.trailingAnchor, constant: -16),
            assigneeNameLabel.centerYAnchor.constraint(equalTo: assignedToCardView.centerYAnchor),
            assigneeNameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: assignedToStaticLabel.trailingAnchor, constant: 8),

            // ── Status Card ────────────────────────────────────────────────
            statusCardView.topAnchor.constraint(equalTo: assignedToCardView.bottomAnchor, constant: cardSpacing),
            statusCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            statusCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            statusCardView.heightAnchor.constraint(equalToConstant: 50),

            statusStaticLabel.leadingAnchor.constraint(equalTo: statusCardView.leadingAnchor, constant: 16),
            statusStaticLabel.centerYAnchor.constraint(equalTo: statusCardView.centerYAnchor),

            statusValueLabel.trailingAnchor.constraint(equalTo: statusCardView.trailingAnchor, constant: -16),
            statusValueLabel.centerYAnchor.constraint(equalTo: statusCardView.centerYAnchor),

            // ── Action Buttons ─────────────────────────────────────────────
            rejectButton.topAnchor.constraint(equalTo: statusCardView.bottomAnchor, constant: 36),
            rejectButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 48),
            rejectButton.widthAnchor.constraint(equalToConstant: 110),
            rejectButton.heightAnchor.constraint(equalToConstant: 44),

            completeButton.topAnchor.constraint(equalTo: statusCardView.bottomAnchor, constant: 36),
            completeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -48),
            completeButton.widthAnchor.constraint(equalToConstant: 110),
            completeButton.heightAnchor.constraint(equalToConstant: 44),

            completeButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
        ])
    }

    // MARK: - Card & Style Helpers

    private func makeCard() -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    private func makeSeparator() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor.systemGray4
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    private func styleCards() {
        [titleCardView, attachmentCardView, descriptionCardView,
         assignedToCardView, statusCardView].forEach {
            AppTheme.styleElevatedCard($0, cornerRadius: 20)
        }
    }

    private func styleBackButton() {
        let foreground = traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
        var cfg = UIButton.Configuration.plain()
        cfg.image = UIImage(systemName: "chevron.left")
        cfg.baseForegroundColor = foreground
        cfg.background.backgroundColor = .clear
        cfg.cornerStyle = .capsule
        backButton.configuration = cfg
        AppTheme.styleNativeFloatingControl(backButton, cornerRadius: backButton.bounds.height / 2)
        backButton.backgroundColor = .clear
        backButton.tintColor = foreground
    }

    private func styleActionButtons() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        [rejectButton, completeButton].forEach {
            $0.layer.cornerRadius  = $0.bounds.height / 2
            $0.layer.masksToBounds = true
            $0.backgroundColor = isDark ? UIColor.white.withAlphaComponent(0.12) : .white
            AppTheme.styleNativeFloatingControl($0, cornerRadius: $0.bounds.height / 2)
        }
        rejectButton.setTitleColor(.systemRed,    for: .normal)
        completeButton.setTitleColor(.systemGreen, for: .normal)
    }

    private func applyThemeFontsAndColors() {
        taskTitleLabel.textColor     = .label
        titleLabel.textColor         = .label
        dueDateValueLabel.textColor  = .label
        assigneeNameLabel.textColor  = .label
        remarkTextView.textColor = remarkTextView.text == remarkPlaceholder ? .systemGray3 : .label
    }

    private func setupRemarkTextView() {
        remarkTextView.delegate   = self
        remarkTextView.text       = remarkPlaceholder
        remarkTextView.textColor  = .systemGray3
        remarkTextView.font       = UIFont.systemFont(ofSize: 16)
    }

    private func setupRefreshControl() {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        scrollView.refreshControl = rc
    }

    // MARK: - Supabase Load

    private func loadFromSupabase() async {
        guard !taskId.isEmpty else { return }

        do {
            struct TaskRow: Decodable {
                let title:              String?
                let assigned_date:      String?
                let remark_description: String?
                let status:             String?
            }

            let rows: [TaskRow] = try await SupabaseManager.shared.client
                .from("tasks")
                .select("title, assigned_date, remark_description, status")
                .eq("id", value: taskId)
                .limit(1)
                .execute()
                .value

            guard let row = rows.first else {
                await MainActor.run { scrollView.refreshControl?.endRefreshing() }
                return
            }

            var assignee = "Team"
            if !teamId.isEmpty {
                assignee = (try? await SupabaseManager.shared
                    .resolveAssigneeNameFromNewTeams(taskId: taskId, teamId: teamId)) ?? "Team"
            }

            let allAttachments      = (try? await SupabaseManager.shared.fetchTaskAttachments(taskId: taskId)) ?? []
            let studentAttachments  = allAttachments.filter { $0.mentor_attachment == false || $0.mentor_attachment == nil }
            let firstName           = studentAttachments.first?.filename
            let dueDateStr          = formatISO(row.assigned_date)

            await MainActor.run {
                taskTitleLabel.text    = row.title ?? taskTitle ?? "—"
                dueDateValueLabel.text = dueDateStr
                assigneeNameLabel.text = assignee
                applyStatusUI(for: row.status ?? "for_review")

                let existingRemark = row.remark_description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if existingRemark.isEmpty {
                    remarkTextView.text      = remarkPlaceholder
                    remarkTextView.textColor = .systemGray3
                } else {
                    remarkTextView.text      = existingRemark
                    remarkTextView.textColor = .label
                }

                self.fetchedAttachments = studentAttachments
                firstAttachmentName     = firstName

                if let name = firstName {
                    let isLink  = name.hasPrefix("http://") || name.hasPrefix("https://")
                    let display = isLink ? (URL(string: name)?.host ?? name) : name
                    attachmentFileNameButton.setTitle(display, for: .normal)
                    attachmentFileNameButton.setTitleColor(.label, for: .normal)
                    attachmentFileNameButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
                    attachmentFileNameButton.isEnabled = true
                    // Set icon based on file type
                    let ext = (name as NSString).pathExtension.lowercased()
                    let iconName: String
                    if isLink {
                        iconName = "link"
                        attachmentIconBackground.backgroundColor = .systemBlue
                    } else if ["jpg","jpeg","png","heic","gif"].contains(ext) {
                        iconName = "photo.fill"
                        attachmentIconBackground.backgroundColor = .systemBlue
                    } else if ext == "pdf" {
                        iconName = "doc.fill"
                        attachmentIconBackground.backgroundColor = .systemRed
                    } else {
                        iconName = "doc.fill"
                        attachmentIconBackground.backgroundColor = .systemGray
                    }
                    attachmentTypeIconView.image = UIImage(systemName: iconName)
                    attachmentRowView.isHidden = false
                } else {
                    attachmentFileNameButton.setTitle("No attachment", for: .normal)
                    attachmentFileNameButton.setTitleColor(.systemGray3, for: .normal)
                    attachmentFileNameButton.isEnabled = false
                    attachmentTypeIconView.image = UIImage(systemName: "paperclip")
                    attachmentIconBackground.backgroundColor = .systemGray3
                    attachmentRowView.isHidden = false
                }

                scrollView.refreshControl?.endRefreshing()
            }

        } catch {
            print("❌ ReviewViewController.loadFromSupabase:", error)
            await MainActor.run {
                attachmentFileNameButton.setTitle("Could not load", for: .normal)
                attachmentFileNameButton.setTitleColor(.systemGray3, for: .normal)
                attachmentFileNameButton.isEnabled = false
                scrollView.refreshControl?.endRefreshing()
            }
        }
    }

    // MARK: - Status UI

    private func applyStatusUI(for raw: String) {
        statusValueLabel.text      = displayStatus(for: raw)
        statusValueLabel.textColor = statusColor(for: raw)
    }

    private func displayStatus(for raw: String) -> String {
        switch raw {
        case "for_review": return "In Review"
        case "approved":   return "Approved"
        case "completed":  return "Completed"
        case "rejected":   return "Rejected"
        case "assigned":   return "Assigned"
        case "ongoing":    return "Ongoing"
        default:           return raw.capitalized
        }
    }

    private func statusColor(for raw: String) -> UIColor {
        switch raw {
        case "for_review": return .systemYellow
        case "approved":   return .systemGreen
        case "completed":  return .systemGreen
        case "rejected":   return .systemRed
        default:           return .systemBlue
        }
    }

    // MARK: - Date Format

    private func formatISO(_ raw: String?) -> String {
        guard let raw else { return "—" }
        let f1 = ISO8601DateFormatter()
        f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let f2 = ISO8601DateFormatter()
        if let d = f1.date(from: raw) ?? f2.date(from: raw) {
            let df = DateFormatter()
            df.dateFormat = "dd MMM yyyy"
            return df.string(from: d)
        }
        return raw
    }

    // MARK: - Actions

    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }

    @objc private func handleRefresh() {
        Task { await loadFromSupabase() }
    }

    @objc private func attachmentButtonTapped() {
        guard let name = firstAttachmentName else { return }

        let isLink = name.hasPrefix("http://") || name.hasPrefix("https://")
        if isLink, let url = URL(string: name) {
            let safari = SFSafariViewController(url: url)
            safari.modalPresentationStyle = .pageSheet
            present(safari, animated: true)
            return
        }

        if let attachmentRow = fetchedAttachments.first(where: { $0.filename == name }),
           let base64 = attachmentRow.file_data,
           let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters),
           let image = UIImage(data: data) {
            let viewer = AttachmentViewerViewController(attachments: [image], attachmentFilenames: [name])
            viewer.modalPresentationStyle = .fullScreen
            present(viewer, animated: true)
            return
        }

        let a = UIAlertController(title: "Attachment", message: name, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    @objc private func rejectButtonTapped() {
        guard !isUpdating else { return }
        let a = UIAlertController(title: "Reject Task",
                                  message: "Are you sure you want to reject this task?",
                                  preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        a.addAction(UIAlertAction(title: "Reject", style: .destructive) { [weak self] _ in
            self?.commitStatusUpdate("rejected")
        })
        present(a, animated: true)
    }

    @objc private func completeButtonTapped() {
        guard !isUpdating else { return }
        let a = UIAlertController(title: "Approve Task",
                                  message: "Mark this task as approved?",
                                  preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        a.addAction(UIAlertAction(title: "Approve", style: .default) { [weak self] _ in
            self?.commitStatusUpdate("approved")
        })
        present(a, animated: true)
    }

    // MARK: - Supabase Update

    private func commitStatusUpdate(_ newStatus: String) {
        guard !taskId.isEmpty else {
            showAlert(title: "Error", message: "Task ID is missing.")
            return
        }
        isUpdating = true

        let remarkText: String? = {
            let t = remarkTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
            return (t.isEmpty || t == remarkPlaceholder) ? nil : t
        }()

        Task {
            do {
                struct TaskUpdate: Encodable {
                    let status:             String
                    let remark:             String
                    let remark_description: String?
                    let updated_at:         String
                }

                let payload = TaskUpdate(
                    status:             newStatus,
                    remark:             newStatus == "rejected" ? "Rejected by mentor" : "Approved by mentor",
                    remark_description: remarkText,
                    updated_at:         ISO8601DateFormatter().string(from: Date())
                )

                try await SupabaseManager.shared.client
                    .from("tasks")
                    .update(payload)
                    .eq("id", value: taskId)
                    .execute()

                if !teamId.isEmpty {
                    try? await SupabaseManager.shared.recalculateAndSyncTeamTaskCounters(teamId: teamId)
                }

                await MainActor.run {
                    self.isUpdating = false
                    self.applyStatusUI(for: newStatus)

                    self.delegate?.reviewViewController(self,
                                                       didChangeStatusTo: newStatus,
                                                       forTaskId: self.taskId)

                    let title   = newStatus == "rejected" ? "Task Rejected"  : "Task Approved"
                    let message = newStatus == "rejected"
                        ? "The task has been rejected successfully."
                        : "The task has been marked as approved."

                    let ok = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    ok.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                        self?.dismiss(animated: true)
                    })
                    self.present(ok, animated: true)
                }
            } catch {
                await MainActor.run {
                    self.isUpdating = false
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    // MARK: - UITextViewDelegate

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == remarkPlaceholder {
            textView.text      = ""
            textView.textColor = .label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text      = remarkPlaceholder
            textView.textColor = .systemGray3
        }
    }
}
