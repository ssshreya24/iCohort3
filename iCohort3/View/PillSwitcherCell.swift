//
//  PillSwitcherCollectionViewCell.swift
//  iCohort3
//
//  Created by user@0 on 11/11/25.
//

import UIKit

class PillSwitcherCell: UICollectionViewCell {
    @IBOutlet weak var createButton: UIButton!
        @IBOutlet weak var joinButton: UIButton!

    private var onCreate: (() -> Void)?
        private var onJoin: (() -> Void)?

        override func awakeFromNib() {
            super.awakeFromNib()
            styleButtons()
        }

        private func styleButtons() {
            let buttons = [createButton, joinButton]

            buttons.forEach {
                $0?.layer.cornerRadius = 20
                $0?.clipsToBounds = true
                $0?.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
            }

            createButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.25)
            joinButton.backgroundColor = UIColor.systemGray4
            createButton.setTitleColor(.label, for: .normal)
            joinButton.setTitleColor(.label, for: .normal)
        }

        func configure(onCreate: @escaping () -> Void, onJoin: @escaping () -> Void) {
            self.onCreate = onCreate
            self.onJoin = onJoin

            createButton.removeTarget(nil, action: nil, for: .allEvents)
            joinButton.removeTarget(nil, action: nil, for: .allEvents)

            createButton.addTarget(self, action: #selector(tapCreate), for: .touchUpInside)
            joinButton.addTarget(self, action: #selector(tapJoin), for: .touchUpInside)
        }

        @objc private func tapCreate() { onCreate?() }
        @objc private func tapJoin() { onJoin?() }

}
