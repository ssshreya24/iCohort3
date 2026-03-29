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

        // Gradient for the currently ACTIVE button
        private var activeGradientLayer: CAGradientLayer?
        private weak var activeButton: UIButton?

        override func awakeFromNib() {
            super.awakeFromNib()
            styleButtons()
            DispatchQueue.main.async {
                        self.setActive(button: self.createButton, inactiveButton: self.joinButton)
                    }
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            [createButton, joinButton].forEach {
                $0?.layer.cornerRadius = ($0?.bounds.height ?? 0) / 2
            }

            // Update gradient frame when layout changes
            if let activeButton = activeButton {
                updateGradient(for: activeButton)
            }
        }

        // MARK: - Styling

        private func styleButtons() {
            [createButton, joinButton].forEach { button in
                button?.clipsToBounds = true
                button?.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
                button?.setTitleColor(.black, for: .normal)
                button?.backgroundColor = .clear
            }
        }

        private func applyActiveStyle(to button: UIButton) {
            button.layer.borderColor = UIColor.white.cgColor
            button.layer.borderWidth = 1.5
            updateGradient(for: button)
        }

        private func applyInactiveStyle(to button: UIButton) {
            button.layer.borderWidth = 0
            button.backgroundColor = UIColor(red: 0.82, green: 0.82, blue: 0.82, alpha: 1.0) // warm grey
            // remove gradient if it was on this button
            activeGradientLayer?.removeFromSuperlayer()
        }

        private func updateGradient(for button: UIButton) {
            activeGradientLayer?.removeFromSuperlayer()

            let gradient = CAGradientLayer()
            gradient.frame = button.bounds
            gradient.cornerRadius = button.bounds.height / 2
            gradient.colors = [
                UIColor(red: 0.75, green: 0.85, blue: 0.93, alpha: 1).cgColor, // top lighter
                UIColor(red: 0.53, green: 0.65, blue: 0.76, alpha: 1).cgColor  // bottom darker
            ]
            gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
            gradient.endPoint   = CGPoint(x: 0.5, y: 1.0)

            button.layer.insertSublayer(gradient, at: 0)
            activeGradientLayer = gradient
        }

        private func setActive(button: UIButton, inactiveButton: UIButton) {
            // inactive styling for the other button
            applyInactiveStyle(to: inactiveButton)

            // active styling for this button
            activeButton = button
            button.backgroundColor = .clear
            applyActiveStyle(to: button)
        }

        // MARK: - Public API

        func configure(onCreate: @escaping () -> Void, onJoin: @escaping () -> Void) {
            self.onCreate = onCreate
            self.onJoin = onJoin

            createButton.removeTarget(nil, action: nil, for: .allEvents)
            joinButton.removeTarget(nil, action: nil, for: .allEvents)

            createButton.addTarget(self, action: #selector(tapCreate), for: .touchUpInside)
            joinButton.addTarget(self, action: #selector(tapJoin), for: .touchUpInside)
        }

        @objc private func tapCreate() {
            setActive(button: createButton, inactiveButton: joinButton)
            onCreate?()
        }

        @objc private func tapJoin() {
            setActive(button: joinButton, inactiveButton: createButton)
            onJoin?()
        }

}
