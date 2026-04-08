import UIKit
import ObjectiveC

private var keyboardDismissTapGestureKey: UInt8 = 0
private var keyboardDismissDelegateKey: UInt8 = 0

private final class KeyboardDismissGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let touchedView = touch.view else { return true }
        return !touchedView.isEmbeddedInTextInput
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}

private extension UIView {
    var isEmbeddedInTextInput: Bool {
        sequence(first: self, next: \.superview).contains {
            $0 is UITextField || $0 is UITextView || $0 is UISearchBar
        }
    }

    func allSubviewsRecursively() -> [UIView] {
        subviews + subviews.flatMap { $0.allSubviewsRecursively() }
    }
}

extension UIViewController {
    func enableKeyboardDismissOnTap() {
        guard objc_getAssociatedObject(self, &keyboardDismissTapGestureKey) as? UITapGestureRecognizer == nil else {
            return
        }

        let delegate = KeyboardDismissGestureDelegate()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleKeyboardDismissTap))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = delegate

        view.addGestureRecognizer(tapGesture)

        objc_setAssociatedObject(self, &keyboardDismissTapGestureKey, tapGesture, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &keyboardDismissDelegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        view.allSubviewsRecursively()
            .compactMap { $0 as? UIScrollView }
            .forEach { scrollView in
                if scrollView.keyboardDismissMode == .none {
                    scrollView.keyboardDismissMode = .interactive
                }
            }
    }

    @objc private func handleKeyboardDismissTap() {
        view.endEditing(true)
    }

    func presentAsProfileSheet(_ viewController: UIViewController, animated: Bool = true) {
        viewController.modalPresentationStyle = .pageSheet
        viewController.modalTransitionStyle = .coverVertical

        if let sheet = viewController.sheetPresentationController {
            sheet.detents = [
                .custom(identifier: .init("almostFull")) { context in
                    context.maximumDetentValue
                }
            ]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }

        present(viewController, animated: animated)
    }
}
