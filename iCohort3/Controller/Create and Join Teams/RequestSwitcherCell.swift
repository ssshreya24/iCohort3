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

        override func awakeFromNib() {
            super.awakeFromNib()
            setupAppearance()
            wireAction()
        }

        private func setupAppearance() {
            if segmented.numberOfSegments == 0 {
                segmented.insertSegment(withTitle: "Requests Send ↑", at: 0, animated: false)
                segmented.insertSegment(withTitle: "Requests Received ↓", at: 1, animated: false)
            }
            segmented.selectedSegmentTintColor = .systemBlue.withAlphaComponent(0.18)
            let normalAttrs: [NSAttributedString.Key : Any] = [
                .foregroundColor: UIColor.label,
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
            ]
            segmented.setTitleTextAttributes(normalAttrs, for: .normal)
            segmented.setTitleTextAttributes(normalAttrs, for: .selected)
        }

        private func wireAction() {
            segmented.removeTarget(nil, action: nil, for: .allEvents)
            segmented.addTarget(self, action: #selector(segChanged), for: .valueChanged)
        }

        @objc private func segChanged() {
            // true => Sent (index 0), false => Received (index 1)
            onToggle?(segmented.selectedSegmentIndex == 0)
        }

        /// Call from your controller to set state + callback
        func configure(showingSent: Bool, onToggle: @escaping (Bool) -> Void) {
            self.onToggle = onToggle
            if segmented.numberOfSegments == 0 {
                // Safety if awakeFromNib hasn’t run yet
                setupAppearance()
            }
            segmented.selectedSegmentIndex = showingSent ? 0 : 1
            wireAction()
        }
    }



