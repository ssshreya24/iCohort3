//
//  RequestsSwitcherCell.swift
//  iCohort3
//
//  Created by user@0 on 12/11/25.
//

import UIKit

class RequestSwitcherCell: UICollectionViewCell {

        @IBOutlet weak var segmented: UISegmentedControl!

        private var onToggle: ((Bool) -> Void)?
        private var onSegmentChanged: ((Int) -> Void)?

        override func awakeFromNib() {
            super.awakeFromNib()
            setupAppearance()
            wireAction()
        }

        private func setupAppearance() {
            segmented.removeAllSegments()
            segmented.insertSegment(withTitle: "Send Requests", at: 0, animated: false)
            segmented.insertSegment(withTitle: "Received", at: 1, animated: false)
            segmented.insertSegment(withTitle: "Join a Team", at: 2, animated: false)
            contentView.backgroundColor = .clear
            backgroundColor = .clear
            segmented.backgroundColor = AppTheme.cardBackground
            segmented.selectedSegmentTintColor = AppTheme.accent.withAlphaComponent(0.28)
            let normalAttrs: [NSAttributedString.Key : Any] = [
                .foregroundColor: UIColor.secondaryLabel,
                .font: UIFont.systemFont(ofSize: 13, weight: .semibold)
            ]
            let selectedAttrs: [NSAttributedString.Key : Any] = [
                .foregroundColor: UIColor.label,
                .font: UIFont.systemFont(ofSize: 13, weight: .semibold)
            ]
            segmented.setTitleTextAttributes(normalAttrs, for: .normal)
            segmented.setTitleTextAttributes(selectedAttrs, for: .selected)
        }

        private func wireAction() {
            segmented.removeTarget(nil, action: nil, for: .allEvents)
            segmented.addTarget(self, action: #selector(segChanged), for: .valueChanged)
        }

        @objc private func segChanged() {
            onToggle?(segmented.selectedSegmentIndex == 0)
            onSegmentChanged?(segmented.selectedSegmentIndex)
        }

        /// Legacy 2-tab configure (for JoinTeamsViewController compatibility)
        func configure(showingSent: Bool, onToggle: @escaping (Bool) -> Void) {
            self.onToggle = onToggle
            self.onSegmentChanged = nil
            if segmented.numberOfSegments < 2 {
                setupAppearance()
            }
            segmented.selectedSegmentIndex = showingSent ? 0 : 1
            wireAction()
        }

        /// 3-tab configure (for merged TeamViewController)
        func configure(selectedIndex: Int, onSegmentChanged: @escaping (Int) -> Void) {
            self.onSegmentChanged = onSegmentChanged
            self.onToggle = nil
            if segmented.numberOfSegments < 3 {
                setupAppearance()
            }
            segmented.selectedSegmentIndex = selectedIndex
            wireAction()
        }
    }


