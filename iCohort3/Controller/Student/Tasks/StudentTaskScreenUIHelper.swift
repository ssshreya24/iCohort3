import UIKit

enum StudentTaskScreenUIHelper {
    static func removeLegacyHeader(from view: UIView, collectionView: UIView) {
        let legacyLabels = view.subviews.compactMap { $0 as? UILabel }

        for label in legacyLabels {
            let relatedConstraints = view.constraints.filter {
                ($0.firstItem as? UIView) === label ||
                ($0.secondItem as? UIView) === label
            }
            NSLayoutConstraint.deactivate(relatedConstraints)
            label.removeFromSuperview()
        }

        let collectionTopConstraints = view.constraints.filter {
            (($0.firstItem as? UIView) === collectionView && $0.firstAttribute == .top) ||
            (($0.secondItem as? UIView) === collectionView && $0.secondAttribute == .top)
        }
        NSLayoutConstraint.deactivate(collectionTopConstraints)

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor)
        ])

        if let scrollView = collectionView as? UIScrollView {
            scrollView.contentInsetAdjustmentBehavior = .automatic
            scrollView.alwaysBounceVertical = true
        }
    }

    static func makeCloseBarButton(target: Any?, action: Selector) -> UIBarButtonItem {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: target,
            action: action
        )
        button.tintColor = AppTheme.accent
        return button
    }

    /// Returns an iPad-aware card size for student task collection views.
    /// - Uses 2 columns with 20pt gutters on regular-width (iPad) screens.
    /// - Falls back to full-width minus 40pt on compact (iPhone) screens.
    static func cardSize(in collectionView: UICollectionView,
                         traitCollection: UITraitCollection,
                         height: CGFloat) -> CGSize {
        if traitCollection.horizontalSizeClass == .regular {
            // iPad — 2-column grid
            let totalPadding: CGFloat = 20 + 20 + 16  // leading + trailing + gutter
            let cardWidth = (collectionView.frame.width - totalPadding) / 2
            return CGSize(width: min(cardWidth, 480), height: height)
        } else {
            return CGSize(width: collectionView.frame.width - 40, height: height)
        }
    }
}
