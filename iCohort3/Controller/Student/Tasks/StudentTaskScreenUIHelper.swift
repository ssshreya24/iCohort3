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
}
