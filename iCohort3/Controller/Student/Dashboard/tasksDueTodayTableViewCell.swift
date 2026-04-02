//
//  tasksDueTodayTableViewCell.swift
//  iCohort3
//

import UIKit

class tasksDueTodayTableViewCell: UITableViewCell {

    @IBOutlet weak var chevronRight: UIButton!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var assignedTo: UILabel!
    @IBOutlet weak var taskDescription: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var cardView: UIView!

    private let card          = UIView()
    private let outerCircle   = UIView()
    private let innerCircle   = UIView()
    private let titleLabel    = UILabel()
    private let subtitleLabel = UILabel()
    private let chevronImage  = UIImageView()
    private var didBuildUI    = false

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor             = .clear
        contentView.backgroundColor = .clear
        contentView.subviews.forEach { $0.isHidden = true }
        buildUI()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor             = .clear
        contentView.backgroundColor = .clear
        buildUI()
    }
    required init?(coder: NSCoder) { super.init(coder: coder) }

    private func buildUI() {
        guard !didBuildUI else { return }
        didBuildUI = true

        card.translatesAutoresizingMaskIntoConstraints = false
        AppTheme.styleCard(card, cornerRadius: 18)
        contentView.addSubview(card)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])

        outerCircle.translatesAutoresizingMaskIntoConstraints = false
        outerCircle.backgroundColor  = UIColor.systemOrange.withAlphaComponent(0.15)
        outerCircle.layer.cornerRadius = 28
        outerCircle.clipsToBounds    = true
        card.addSubview(outerCircle)

        NSLayoutConstraint.activate([
            outerCircle.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            outerCircle.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            outerCircle.widthAnchor.constraint(equalToConstant: 56),
            outerCircle.heightAnchor.constraint(equalToConstant: 56),
        ])

        innerCircle.translatesAutoresizingMaskIntoConstraints = false
        innerCircle.backgroundColor  = UIColor.systemOrange
        innerCircle.layer.cornerRadius = 10
        innerCircle.clipsToBounds    = true
        outerCircle.addSubview(innerCircle)

        NSLayoutConstraint.activate([
            innerCircle.centerXAnchor.constraint(equalTo: outerCircle.centerXAnchor),
            innerCircle.centerYAnchor.constraint(equalTo: outerCircle.centerYAnchor),
            innerCircle.widthAnchor.constraint(equalToConstant: 20),
            innerCircle.heightAnchor.constraint(equalToConstant: 20),
        ])

        chevronImage.translatesAutoresizingMaskIntoConstraints = false
        chevronImage.image = UIImage(
            systemName: "chevron.right",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        )?.withTintColor(.tertiaryLabel, renderingMode: .alwaysOriginal)
        chevronImage.contentMode = .scaleAspectFit
        card.addSubview(chevronImage)

        NSLayoutConstraint.activate([
            chevronImage.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            chevronImage.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            chevronImage.widthAnchor.constraint(equalToConstant: 14),
            chevronImage.heightAnchor.constraint(equalToConstant: 14),
        ])

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font          = UIFont.systemFont(ofSize: 13)
        subtitleLabel.textColor     = .secondaryLabel
        subtitleLabel.numberOfLines = 1
        card.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            subtitleLabel.leadingAnchor.constraint(equalTo: outerCircle.trailingAnchor, constant: 14),
            subtitleLabel.trailingAnchor.constraint(equalTo: chevronImage.leadingAnchor, constant: -8),
            subtitleLabel.bottomAnchor.constraint(equalTo: card.centerYAnchor, constant: -1),
        ])

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font          = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor     = .label
        titleLabel.numberOfLines = 1
        card.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: outerCircle.trailingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: chevronImage.leadingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: card.centerYAnchor, constant: 1),
        ])
    }

    func configure(title: String,
                   dueLabel: String,
                   descriptionText: String,
                   colorIndex: Int = 0) {
        titleLabel.text = title

        let duePart  = "Due Today"
        let descPart = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let full     = descPart.isEmpty ? duePart : "\(duePart)  ·  \(descPart)"

        let attr = NSMutableAttributedString(string: full, attributes: [
            .font:            UIFont.systemFont(ofSize: 13),
            .foregroundColor: UIColor.secondaryLabel
        ])
        attr.addAttributes([
            .foregroundColor: UIColor.systemOrange,
            .font:            UIFont.systemFont(ofSize: 13, weight: .semibold)
        ], range: (full as NSString).range(of: duePart))
        subtitleLabel.attributedText = attr
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        outerCircle.layer.cornerRadius = outerCircle.bounds.width / 2
        innerCircle.layer.cornerRadius = innerCircle.bounds.width / 2
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text    = nil
        subtitleLabel.text = nil
    }
}
