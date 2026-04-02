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
    private let divider = UIView()

    private var onTap: (() -> Void)?

    private let accent = UIColor(red: 0x77/255.0, green: 0x9C/255.0, blue: 0xB3/255.0, alpha: 1.0)

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
        nameLabel.text = nil
        subtitleLabel.text = nil
        initialLabel.text = nil
        divider.isHidden = false

        avatarImageView.image = nil
        avatarImageView.isHidden = true
        initialLabel.isHidden = false

        actionButton.setTitle(nil, for: .normal)
        actionButton.isEnabled = true
        actionButton.alpha = 1.0

        actionButton.layer.borderColor = accent.withAlphaComponent(0.85).cgColor
        actionButton.tintColor = accent
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        avatarCircle.layer.cornerRadius = avatarCircle.bounds.height / 2
        avatarCircle.layer.masksToBounds = true

        // ✅ ensure the image also appears circular
        avatarImageView.layer.cornerRadius = avatarCircle.bounds.height / 2
        avatarImageView.layer.masksToBounds = true

        actionButton.layer.cornerRadius = actionButton.bounds.height / 2
        actionButton.layer.masksToBounds = true
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
        avatarCircle.backgroundColor = accent.withAlphaComponent(0.22)

        NSLayoutConstraint.activate([
            avatarCircle.widthAnchor.constraint(equalToConstant: 48),
            avatarCircle.heightAnchor.constraint(equalToConstant: 48),
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
        initialLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        initialLabel.textColor = .label
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

        nameLabel.font = .systemFont(ofSize: 20, weight: .bold)
        nameLabel.textColor = .label
        nameLabel.numberOfLines = 1

        subtitleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 1

        textStack.addArrangedSubview(nameLabel)
        textStack.addArrangedSubview(subtitleLabel)

        // Action button
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        actionButton.tintColor = accent
        actionButton.backgroundColor = .clear
        actionButton.layer.borderWidth = 1.5
        actionButton.layer.borderColor = accent.withAlphaComponent(0.85).cgColor
        actionButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 18, bottom: 10, right: 18)

        // ✅ prevent button shrinking weirdly
        actionButton.setContentHuggingPriority(.required, for: .horizontal)
        actionButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        actionButton.addTarget(self, action: #selector(didTap), for: .touchUpInside)

        // Spacer
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        // Assemble
        rootStack.addArrangedSubview(avatarCircle)
        rootStack.addArrangedSubview(textStack)
        rootStack.addArrangedSubview(spacer)
        rootStack.addArrangedSubview(actionButton)

        // Divider
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = UIColor.separator.withAlphaComponent(0.4)
        contentView.addSubview(divider)

        NSLayoutConstraint.activate([
            divider.heightAnchor.constraint(equalToConstant: 1),
            divider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 80),
            divider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            divider.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    @objc private func didTap() {
        onTap?()
    }

    // MARK: - Public Configs

    /// Student list row (Send Requests tab)
    func configure(
        name: String,
        subtitle: String,
        avatar: UIImage? = nil,
        onTap: @escaping () -> Void,
        showsDivider: Bool = true
    ) {
        self.onTap = onTap
        actionButton.setTitle("Add", for: .normal)
        actionButton.isEnabled = true
        actionButton.alpha = 1.0
        apply(name: name, subtitle: subtitle, avatar: avatar, showsDivider: showsDivider)
    }

    /// After invite already sent (optional usage)
    func configureForSent(
        name: String,
        avatar: UIImage? = nil,
        showsDivider: Bool = true
    ) {
        self.onTap = nil
        actionButton.setTitle("Sent", for: .normal)
        actionButton.isEnabled = false
        actionButton.alpha = 0.7
        apply(name: name, subtitle: "Invite Sent", avatar: avatar, showsDivider: showsDivider)
    }

    /// Received request row (Received Requests tab)
    func configureForReceived(
        name: String,
        avatar: UIImage? = nil,
        showsDivider: Bool = true,
        onTap: @escaping () -> Void
    ) {
        self.onTap = onTap
        actionButton.setTitle("Accept", for: .normal)
        actionButton.isEnabled = true
        actionButton.alpha = 1.0
        apply(name: name, subtitle: "Invited you to join", avatar: avatar, showsDivider: showsDivider)
    }

    /// ✅ Use this when limit reached OR you want to disable Add for a student
    func configureDisabled(
        name: String,
        subtitle: String,
        avatar: UIImage? = nil,
        showsDivider: Bool = true
    ) {
        self.onTap = nil
        actionButton.setTitle("Add", for: .normal)
        actionButton.isEnabled = false
        actionButton.alpha = 0.5
        apply(name: name, subtitle: subtitle, avatar: avatar, showsDivider: showsDivider)
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
            : accent.withAlphaComponent(0.22)
        divider.backgroundColor = UIColor.separator.withAlphaComponent(isDark ? 0.28 : 0.4)
        actionButton.backgroundColor = isDark ? AppTheme.floatingBackground : .clear
        actionButton.layer.borderColor = AppTheme.accent.withAlphaComponent(isDark ? 0.45 : 0.85).cgColor
        actionButton.tintColor = AppTheme.accent
        nameLabel.textColor = .label
        subtitleLabel.textColor = .secondaryLabel
        initialLabel.textColor = .label
    }
}
