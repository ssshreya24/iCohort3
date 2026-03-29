//
//  EmptyStateCollectionViewCell.swift
//  iCohort3
//
//  Created by admin100 on 13/01/26.
//

import UIKit

final class EmptyStateCollectionViewCell: UICollectionViewCell {

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = UIColor(white: 0.65, alpha: 1.0)
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        contentView.backgroundColor = .clear
        contentView.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            messageLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            messageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    func configure(with message: String) {
        messageLabel.text = message
    }
}
