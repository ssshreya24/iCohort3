import UIKit

final class MemberAvatarCell: UICollectionViewCell {

    private let circleContainerView = UIView()
    private let avatarImageView = UIImageView()
    private let initialLabel = UILabel()
    private let plusImageView = UIImageView()

    private let nameLabel = UILabel()
    private let regNoLabel = UILabel()
    private let deptLabel = UILabel()

    private let textStack = UIStackView()
    private let rootStack = UIStackView()

    private var onTapAdd: (() -> Void)?

    private let circleSize: CGFloat = 64
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
        onTapAdd = nil
        contentView.isUserInteractionEnabled = false

        nameLabel.text = ""
        regNoLabel.text = ""
        deptLabel.text = ""

        initialLabel.isHidden = true
        plusImageView.isHidden = true
        avatarImageView.isHidden = false

        circleContainerView.backgroundColor = .clear
        avatarImageView.tintColor = accent
        avatarImageView.image = nil
    }

    private func buildUI() {
        contentView.backgroundColor = .clear

        // Root vertical stack
        rootStack.axis = .vertical
        rootStack.alignment = .center
        rootStack.distribution = .fill
        rootStack.spacing = 8
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            rootStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -4),
        ])

        // Circle container (✅ set cornerRadius immediately so it NEVER shows square)
        circleContainerView.translatesAutoresizingMaskIntoConstraints = false
        circleContainerView.backgroundColor = .clear
        circleContainerView.layer.cornerRadius = circleSize / 2
        circleContainerView.layer.masksToBounds = true

        NSLayoutConstraint.activate([
            circleContainerView.widthAnchor.constraint(equalToConstant: circleSize),
            circleContainerView.heightAnchor.constraint(equalToConstant: circleSize),
        ])

        // Avatar image (slightly smaller so plus overlays nicely)
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.contentMode = .scaleAspectFit
        avatarImageView.tintColor = accent

        // Initial label (tile 1)
        initialLabel.translatesAutoresizingMaskIntoConstraints = false
        initialLabel.textAlignment = .center
        initialLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        initialLabel.textColor = .white
        initialLabel.isHidden = true

        // Plus overlay (✅ kept INSIDE circle)
        plusImageView.translatesAutoresizingMaskIntoConstraints = false
        plusImageView.image = UIImage(systemName: "plus.circle.fill")
        plusImageView.tintColor = accent
        plusImageView.isHidden = true

        circleContainerView.addSubview(avatarImageView)
        circleContainerView.addSubview(initialLabel)
        circleContainerView.addSubview(plusImageView)

        NSLayoutConstraint.activate([
            avatarImageView.centerXAnchor.constraint(equalTo: circleContainerView.centerXAnchor),
            avatarImageView.centerYAnchor.constraint(equalTo: circleContainerView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 60),
            avatarImageView.heightAnchor.constraint(equalToConstant: 60),

            initialLabel.centerXAnchor.constraint(equalTo: circleContainerView.centerXAnchor),
            initialLabel.centerYAnchor.constraint(equalTo: circleContainerView.centerYAnchor),

            plusImageView.trailingAnchor.constraint(equalTo: circleContainerView.trailingAnchor, constant: -6),
            plusImageView.bottomAnchor.constraint(equalTo: circleContainerView.bottomAnchor, constant: -8),
            plusImageView.widthAnchor.constraint(equalToConstant: 20),
            plusImageView.heightAnchor.constraint(equalToConstant: 20),
        ])

        // Text stack
        textStack.axis = .vertical
        textStack.alignment = .center
        textStack.distribution = .fill
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 1

        regNoLabel.font = .systemFont(ofSize: 11, weight: .regular)
        regNoLabel.textColor = .secondaryLabel
        regNoLabel.textAlignment = .center
        regNoLabel.numberOfLines = 1

        deptLabel.font = .systemFont(ofSize: 11, weight: .regular)
        deptLabel.textColor = .secondaryLabel
        deptLabel.textAlignment = .center
        deptLabel.numberOfLines = 1

        textStack.addArrangedSubview(nameLabel)
        textStack.addArrangedSubview(regNoLabel)
        textStack.addArrangedSubview(deptLabel)

        rootStack.addArrangedSubview(circleContainerView)
        rootStack.addArrangedSubview(textStack)

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        contentView.addGestureRecognizer(tap)
    }

    @objc private func didTap() {
        onTapAdd?()
    }

    func configure(
        slot: MemberSlot,
        name: String?,
        regNo: String?,
        dept: String?,
        onTapAdd: (() -> Void)?
    ) {
        self.onTapAdd = nil
        contentView.isUserInteractionEnabled = false

        nameLabel.text = name ?? ""
        regNoLabel.text = regNo ?? ""
        deptLabel.text = dept ?? ""

        initialLabel.isHidden = true
        plusImageView.isHidden = true
        avatarImageView.isHidden = false

        circleContainerView.backgroundColor = .clear
        avatarImageView.tintColor = accent

        switch slot {
        case .currentInitial(let ch):
            // ✅ Real circle with background
            avatarImageView.isHidden = true
            initialLabel.isHidden = false
            initialLabel.text = ch.uppercased()
            circleContainerView.backgroundColor = UIColor(red: 0x77/255.0, green: 0x9C/255.0, blue: 0xB3/255.0, alpha: 0.60)

        case .addSlot:
            // ✅ person.circle + plus overlay on top
            contentView.isUserInteractionEnabled = true
            self.onTapAdd = onTapAdd

            avatarImageView.image = UIImage(systemName: "person.circle")?.withRenderingMode(.alwaysTemplate)
            avatarImageView.tintColor = accent
            plusImageView.isHidden = false

        case .filled(let img):
            avatarImageView.image = img.withRenderingMode(.alwaysOriginal)

        case .empty:
            // If you want empty to look same as add but not tappable:
            avatarImageView.image = UIImage(systemName: "person.circle")?.withRenderingMode(.alwaysTemplate)
            avatarImageView.tintColor = accent
            plusImageView.isHidden = false
        }
    }
}
