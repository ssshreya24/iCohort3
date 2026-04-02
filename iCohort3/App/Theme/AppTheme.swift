import UIKit

enum AppTheme {
    private static let gradientLayerName = "AppThemeGradientLayer"
    private static let floatingBlurViewTag = 909_001
    private static let floatingOverlayViewTag = 909_002

    static let accent = UIColor { trait in
        if trait.userInterfaceStyle == .dark {
            return UIColor(red: 0.61, green: 0.77, blue: 0.92, alpha: 1.0)
        }
        return UIColor(red: 0.20, green: 0.31, blue: 0.43, alpha: 1.0)
    }

    static let screenGradientStart = UIColor { trait in
        if trait.userInterfaceStyle == .dark {
            return UIColor(red: 0.13, green: 0.17, blue: 0.23, alpha: 1.0)
        }
        return UIColor(red: 0.78, green: 0.88, blue: 0.95, alpha: 1.0)
    }

    static let screenGradientEnd = UIColor { trait in
        if trait.userInterfaceStyle == .dark {
            return UIColor(red: 0.05, green: 0.07, blue: 0.11, alpha: 1.0)
        }
        return UIColor(white: 0.95, alpha: 1.0)
    }

    static let cardBackground = UIColor { trait in
        if trait.userInterfaceStyle == .dark {
            return UIColor(red: 0.12, green: 0.14, blue: 0.18, alpha: 0.96)
        }
        return .white
    }

    static let floatingBackground = UIColor { trait in
        if trait.userInterfaceStyle == .dark {
            return UIColor(red: 0.16, green: 0.19, blue: 0.24, alpha: 0.98)
        }
        return .white
    }

    static let borderColor = UIColor { trait in
        if trait.userInterfaceStyle == .dark {
            return UIColor.white.withAlphaComponent(0.08)
        }
        return UIColor.black.withAlphaComponent(0.05)
    }

    static let elevatedCardBackground = UIColor { trait in
        if trait.userInterfaceStyle == .dark {
            return UIColor(red: 0.15, green: 0.17, blue: 0.22, alpha: 0.98)
        }
        return .white
    }

    static func configureGlobalAppearance() {
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterial)
        navAppearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.72)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().tintColor = accent
    }

    static func configureTabBarAppearance(_ tabBar: UITabBar) {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = floatingBackground.resolvedColor(with: tabBar.traitCollection)

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor.secondaryLabel
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.secondaryLabel
        ]
        itemAppearance.selected.iconColor = accent
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: accent
        ]

        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
    }

    static func applyScreenBackground(to view: UIView) {
        let gradientLayer: CAGradientLayer

        if let existing = view.layer.sublayers?.first(where: { $0.name == gradientLayerName }) as? CAGradientLayer {
            gradientLayer = existing
        } else {
            gradientLayer = CAGradientLayer()
            gradientLayer.name = gradientLayerName
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
            view.layer.insertSublayer(gradientLayer, at: 0)
        }

        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            screenGradientStart.resolvedColor(with: view.traitCollection).cgColor,
            screenGradientEnd.resolvedColor(with: view.traitCollection).cgColor
        ]
        view.backgroundColor = .clear
    }

    static func styleCard(_ view: UIView, cornerRadius: CGFloat = 16) {
        view.layer.cornerRadius = cornerRadius
        view.layer.masksToBounds = false
        view.backgroundColor = cardBackground
        view.layer.borderWidth = 1
        view.layer.borderColor = borderColor.resolvedColor(with: view.traitCollection).cgColor
        applyShadow(to: view)
    }

    static func styleElevatedCard(_ view: UIView, cornerRadius: CGFloat = 16) {
        view.layer.cornerRadius = cornerRadius
        view.layer.masksToBounds = false
        view.backgroundColor = elevatedCardBackground
        view.layer.borderWidth = 1
        view.layer.borderColor = borderColor.resolvedColor(with: view.traitCollection).cgColor
        applyShadow(to: view)
    }

    static func styleFloatingControl(_ view: UIView, cornerRadius: CGFloat) {
        view.backgroundColor = floatingBackground
        view.layer.cornerRadius = cornerRadius
        view.layer.borderWidth = 1
        view.layer.borderColor = borderColor.resolvedColor(with: view.traitCollection).cgColor
        applyShadow(to: view)
    }

    static func styleNativeFloatingControl(_ view: UIView, cornerRadius: CGFloat) {
        let blurStyle: UIBlurEffect.Style = view.traitCollection.userInterfaceStyle == .dark
            ? .systemThinMaterialDark
            : .systemThinMaterialLight

        let blurView: UIVisualEffectView
        if let existing = view.viewWithTag(floatingBlurViewTag) as? UIVisualEffectView {
            blurView = existing
            blurView.effect = UIBlurEffect(style: blurStyle)
        } else {
            blurView = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
            blurView.tag = floatingBlurViewTag
            blurView.isUserInteractionEnabled = false
            blurView.translatesAutoresizingMaskIntoConstraints = false
            view.insertSubview(blurView, at: 0)
            NSLayoutConstraint.activate([
                blurView.topAnchor.constraint(equalTo: view.topAnchor),
                blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }

        blurView.layer.cornerRadius = cornerRadius
        blurView.clipsToBounds = true

        let overlay: UIView
        if let existing = view.viewWithTag(floatingOverlayViewTag) {
            overlay = existing
        } else {
            overlay = UIView()
            overlay.tag = floatingOverlayViewTag
            overlay.isUserInteractionEnabled = false
            overlay.translatesAutoresizingMaskIntoConstraints = false
            blurView.contentView.addSubview(overlay)
            NSLayoutConstraint.activate([
                overlay.topAnchor.constraint(equalTo: blurView.contentView.topAnchor),
                overlay.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor),
                overlay.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor),
                overlay.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor)
            ])
        }
        overlay.backgroundColor = view.traitCollection.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.08)
            : UIColor.white.withAlphaComponent(0.44)

        view.backgroundColor = .clear
        view.layer.cornerRadius = cornerRadius
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(
            view.traitCollection.userInterfaceStyle == .dark ? 0.12 : 0.30
        ).cgColor
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = view.traitCollection.userInterfaceStyle == .dark ? 0.24 : 0.14
        view.layer.shadowOffset = CGSize(width: 0, height: 8)
        view.layer.shadowRadius = 18
    }

    static func applyShadow(to view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = view.traitCollection.userInterfaceStyle == .dark ? 0.28 : 0.08
        view.layer.shadowOffset = CGSize(width: 0, height: 3)
        view.layer.shadowRadius = 10
    }
}
