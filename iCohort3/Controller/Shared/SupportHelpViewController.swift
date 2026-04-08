import UIKit

struct ProfileInfoCardContent {
    let title: String
    let body: String
}

class ProfileInfoSheetViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let stackView = UIStackView()
    private var cardTitleLabels: [UILabel] = []
    private var cardBodyLabels: [UILabel] = []

    var sheetTitleText: String { "" }
    var sheetSubtitleText: String { "" }
    var cards: [ProfileInfoCardContent] { [] }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        applyTheme()
    }

    @available(iOS, deprecated: 17.0, message: "Use registerForTraitChanges")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        applyTheme()
    }

    private func buildUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true

        titleLabel.text = sheetTitleText
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)

        subtitleLabel.text = sheetSubtitleText
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.numberOfLines = 0

        stackView.axis = .vertical
        stackView.spacing = 14

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(stackView)

        cards.forEach { card in
            stackView.addArrangedSubview(makeCard(title: card.title, body: card.body))
        }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            stackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    private func makeCard(title: String, body: String) -> UIView {
        let card = UIView()
        let titleLabel = UILabel()
        let bodyLabel = UILabel()
        let innerStack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])

        card.translatesAutoresizingMaskIntoConstraints = false
        innerStack.translatesAutoresizingMaskIntoConstraints = false
        innerStack.axis = .vertical
        innerStack.spacing = 8

        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.numberOfLines = 0
        cardTitleLabels.append(titleLabel)

        bodyLabel.text = body
        bodyLabel.font = .systemFont(ofSize: 15, weight: .regular)
        bodyLabel.numberOfLines = 0
        cardBodyLabels.append(bodyLabel)

        card.addSubview(innerStack)

        NSLayoutConstraint.activate([
            innerStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            innerStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            innerStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            innerStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        return card
    }

    private func applyTheme() {
        AppTheme.applyScreenBackground(to: view)
        titleLabel.textColor = .label
        subtitleLabel.textColor = .secondaryLabel

        for card in stackView.arrangedSubviews {
            AppTheme.styleElevatedCard(card, cornerRadius: 20)
            card.layer.cornerCurve = .continuous
        }

        cardTitleLabels.forEach {
            $0.textColor = UIColor.label
            $0.backgroundColor = UIColor.clear
        }
        cardBodyLabels.forEach {
            $0.textColor = UIColor.secondaryLabel
            $0.backgroundColor = UIColor.clear
        }
    }
}

final class SupportHelpViewController: ProfileInfoSheetViewController {
    override var sheetTitleText: String { "Support & Help" }

    override var sheetSubtitleText: String {
        "Everything you need to understand how to get help inside iCohort."
    }

    override var cards: [ProfileInfoCardContent] {
        [
            ProfileInfoCardContent(
                title: "Account help",
                body: "Use the Details section on your profile to review and update your personal information."
            ),
            ProfileInfoCardContent(
                title: "Team help",
                body: "Open My Team to check your current team status, member count, and next available actions."
            ),
            ProfileInfoCardContent(
                title: "Need more support?",
                body: "If something still looks incorrect, contact your mentor or institute admin for help with account and approval-related issues."
            )
        ]
    }
}

final class PrivacyPolicyViewController: ProfileInfoSheetViewController {
    override var sheetTitleText: String { "Privacy & Policy" }

    override var sheetSubtitleText: String {
        "A quick overview of how iCohort handles your account, profile, and support-related information."
    }

    override var cards: [ProfileInfoCardContent] {
        [
            ProfileInfoCardContent(
                title: "Profile information",
                body: "Your profile details such as name, email, department, and contact information are used to personalize the app experience and connect you with your cohort."
            ),
            ProfileInfoCardContent(
                title: "Team and task data",
                body: "Team membership, progress, approvals, and review activity are stored so mentors, students, and admins can track collaboration and task status inside the app."
            ),
            ProfileInfoCardContent(
                title: "Support and account access",
                body: "When you need help, your account context may be used to troubleshoot sign-in, approvals, notifications, and profile issues more effectively."
            )
        ]
    }
}
