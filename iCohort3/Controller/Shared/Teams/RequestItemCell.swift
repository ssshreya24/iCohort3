import UIKit

final class RequestItemCell: UICollectionViewCell {

    private let rootStack = UIStackView()

    private let avatarCircle = UIView()
    private let avatarImageView = UIImageView()
    private let initialLabel = UILabel()

    private let textStack = UIStackView()
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let actionButton = UIButton(type: .system)
    private let rejectButton = UIButton(type: .system)
    private let buttonStack = UIStackView()
    private let divider = UIView()

    private var onTap: (() -> Void)?
    private var onReject: (() -> Void)?

    private let btnSize: CGFloat = 36

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        buildUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        onTap = nil
        onReject = nil
        nameLabel.text = nil
        subtitleLabel.text = nil
        initialLabel.text = nil
        divider.isHidden = false

        avatarImageView.image = nil
        avatarImageView.isHidden = true
        initialLabel.isHidden = false

        actionButton.setImage(nil, for: .normal)
        actionButton.setTitle(nil, for: .normal)
        actionButton.isEnabled = true
        actionButton.alpha = 1.0
        actionButton.isHidden = false

        rejectButton.setImage(nil, for: .normal)
        rejectButton.setTitle(nil, for: .normal)
        rejectButton.isHidden = true
        rejectButton.isEnabled = true
        rejectButton.alpha = 1.0
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        avatarCircle.layer.cornerRadius = avatarCircle.bounds.height / 2
        avatarCircle.layer.masksToBounds = true

        avatarImageView.layer.cornerRadius = avatarCircle.bounds.height / 2
        avatarImageView.layer.masksToBounds = true

        actionButton.layer.cornerRadius = btnSize / 2
        actionButton.layer.masksToBounds = true

        rejectButton.layer.cornerRadius = btnSize / 2
        rejectButton.layer.masksToBounds = true

        applyTheme()
    }

    private func buildUI() {
        contentView.backgroundColor = .clear
        backgroundColor = .clear

        // Root stack
        rootStack.axis = .horizontal
        rootStack.alignment = .center
        rootStack.distribution = .fill
        rootStack.spacing = 12
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            rootStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])

        // Avatar circle
        avatarCircle.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            avatarCircle.widthAnchor.constraint(equalToConstant: 44),
            avatarCircle.heightAnchor.constraint(equalToConstant: 44),
        ])

        // Avatar image (optional)
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.isHidden = true
        avatarCircle.addSubview(avatarImageView)

        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: avatarCircle.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarCircle.leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: avatarCircle.trailingAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarCircle.bottomAnchor),
        ])

        // Initial label (fallback)
        initialLabel.translatesAutoresizingMaskIntoConstraints = false
        initialLabel.textAlignment = .center
        initialLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        avatarCircle.addSubview(initialLabel)

        NSLayoutConstraint.activate([
            initialLabel.centerXAnchor.constraint(equalTo: avatarCircle.centerXAnchor),
            initialLabel.centerYAnchor.constraint(equalTo: avatarCircle.centerYAnchor),
        ])

        // Text stack
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.distribution = .fill
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.numberOfLines = 1

        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.numberOfLines = 1

        textStack.addArrangedSubview(nameLabel)
        textStack.addArrangedSubview(subtitleLabel)

        // Action button — circle
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.addTarget(self, action: #selector(didTap), for: .touchUpInside)

        NSLayoutConstraint.activate([
            actionButton.widthAnchor.constraint(equalToConstant: btnSize),
            actionButton.heightAnchor.constraint(equalToConstant: btnSize),
        ])
        AppTheme.styleFloatingControl(actionButton, cornerRadius: btnSize / 2)

        // Reject button — circle
        rejectButton.translatesAutoresizingMaskIntoConstraints = false
        rejectButton.isHidden = true
        rejectButton.addTarget(self, action: #selector(didTapReject), for: .touchUpInside)

        NSLayoutConstraint.activate([
            rejectButton.widthAnchor.constraint(equalToConstant: btnSize),
            rejectButton.heightAnchor.constraint(equalToConstant: btnSize),
        ])
        AppTheme.styleFloatingControl(rejectButton, cornerRadius: btnSize / 2)

        // Button stack
        buttonStack.axis = .horizontal
        buttonStack.spacing = 8
        buttonStack.alignment = .fill
        buttonStack.distribution = .fill
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.addArrangedSubview(rejectButton)
        buttonStack.addArrangedSubview(actionButton)

        // Spacer
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        // Assemble
        rootStack.addArrangedSubview(avatarCircle)
        rootStack.addArrangedSubview(textStack)
        rootStack.addArrangedSubview(spacer)
        rootStack.addArrangedSubview(buttonStack)

        // Divider
        divider.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(divider)

        NSLayoutConstraint.activate([
            divider.heightAnchor.constraint(equalToConstant: 0.5),
            divider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 76),
            divider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            divider.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    @objc private func didTap() {
        onTap?()
    }

    @objc private func didTapReject() {
        onReject?()
    }

    // MARK: - SF Symbol helpers

    private func icon(_ systemName: String, weight: UIImage.SymbolWeight = .medium) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: weight)
        return UIImage(systemName: systemName, withConfiguration: config)
    }

    // MARK: - Public Configs

    /// Student list / team list — circular "+" Add action
    func configure(
        name: String,
        subtitle: String,
        avatar: UIImage? = nil,
        onTap: @escaping () -> Void,
        showsDivider: Bool = true
    ) {
        self.onTap = onTap
        self.onReject = nil
        rejectButton.isHidden = true
        setActionIcon(.accent, systemName: "plus", enabled: true)
        apply(name: name, subtitle: subtitle, avatar: avatar, showsDivider: showsDivider)
    }

    /// After invite/request already sent — disabled clock icon
    func configureForSent(
        name: String,
        avatar: UIImage? = nil,
        showsDivider: Bool = true
    ) {
        self.onTap = nil
        self.onReject = nil
        rejectButton.isHidden = true
        setActionIcon(.muted, systemName: "clock", enabled: false)
        apply(name: name, subtitle: "Request Sent", avatar: avatar, showsDivider: showsDivider)
    }

    /// After invite/request sent — circular undo arrow
    func configureForSentWithUndo(
        name: String,
        subtitle: String = "Request Sent",
        avatar: UIImage? = nil,
        showsDivider: Bool = true,
        onUndo: @escaping () -> Void
    ) {
        self.onTap = onUndo
        self.onReject = nil
        rejectButton.isHidden = true
        setActionIcon(.subtle, systemName: "arrow.uturn.backward", enabled: true)
        apply(name: name, subtitle: subtitle, avatar: avatar, showsDivider: showsDivider)
    }

    /// Received request — circular checkmark (accept) + xmark (reject)
    func configureForReceived(
        name: String,
        subtitle: String,
        avatar: UIImage? = nil,
        showsDivider: Bool = true,
        onAccept: @escaping () -> Void,
        onReject: @escaping () -> Void
    ) {
        self.onTap = onAccept
        self.onReject = onReject
        setActionIcon(.accent, systemName: "checkmark", enabled: true)
        setRejectIcon(systemName: "xmark")
        rejectButton.isHidden = false
        apply(name: name, subtitle: subtitle, avatar: avatar, showsDivider: showsDivider)
    }

    /// Legacy single-action received config
    func configureForReceived(
        name: String,
        avatar: UIImage? = nil,
        showsDivider: Bool = true,
        onTap: @escaping () -> Void
    ) {
        self.onTap = onTap
        self.onReject = nil
        rejectButton.isHidden = true
        setActionIcon(.accent, systemName: "checkmark", enabled: true)
        apply(name: name, subtitle: "Wants to join", avatar: avatar, showsDivider: showsDivider)
    }

    /// Disabled state (e.g. invite limit reached)
    func configureDisabled(
        name: String,
        subtitle: String,
        avatar: UIImage? = nil,
        showsDivider: Bool = true
    ) {
        self.onTap = nil
        self.onReject = nil
        rejectButton.isHidden = true
        setActionIcon(.muted, systemName: "plus", enabled: false)
        apply(name: name, subtitle: subtitle, avatar: avatar, showsDivider: showsDivider)
    }

    // MARK: - Button Style Modes

    private enum ButtonStyle {
        case accent   // App accent color (Add, Accept)
        case subtle   // Secondary tone (Undo)
        case muted    // Faded, disabled (Sent, disabled Add)
    }

    private func setActionIcon(_ style: ButtonStyle, systemName: String, enabled: Bool) {
        actionButton.setTitle(nil, for: .normal)
        actionButton.setImage(icon(systemName), for: .normal)
        actionButton.isEnabled = enabled

        switch style {
        case .accent:
            actionButton.tintColor = AppTheme.accent
        case .subtle:
            actionButton.tintColor = .label
        case .muted:
            actionButton.tintColor = .tertiaryLabel
            actionButton.alpha = 0.5
        }
    }

    private func setRejectIcon(systemName: String) {
        rejectButton.setTitle(nil, for: .normal)
        rejectButton.setImage(icon(systemName), for: .normal)
        rejectButton.tintColor = .label
    }

    // MARK: - Helpers

    private func apply(name: String, subtitle: String, avatar: UIImage?, showsDivider: Bool) {
        applyTheme()
        nameLabel.text = name
        subtitleLabel.text = subtitle
        divider.isHidden = !showsDivider

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        initialLabel.text = trimmed.first.map { String($0).uppercased() } ?? "?"

        if let avatar = avatar {
            avatarImageView.image = avatar
            avatarImageView.isHidden = false
            initialLabel.isHidden = true
        } else {
            avatarImageView.image = nil
            avatarImageView.isHidden = true
            initialLabel.isHidden = false
        }
    }

    private func applyTheme() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        avatarCircle.backgroundColor = isDark
            ? AppTheme.cardBackground.withAlphaComponent(0.95)
            : AppTheme.accent.withAlphaComponent(0.12)
        divider.backgroundColor = UIColor.separator.withAlphaComponent(isDark ? 0.18 : 0.25)
        nameLabel.textColor = .label
        subtitleLabel.textColor = .secondaryLabel
        initialLabel.textColor = AppTheme.accent
    }
}
