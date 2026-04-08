import UIKit
import SafariServices

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

    static let buttonColor = UIColor(named: "Button Color") ?? accent

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

final class AnimatedAuthLogoView: UIView {
    private let contentLayer = CALayer()
    private let glowLayer = CAShapeLayer()
    private let detailRingLayer = CAShapeLayer()
    private let orbitGuideLayer = CAShapeLayer()
    private let backOrbitLayer = CAShapeLayer()
    private let frontOrbitLayer = CAShapeLayer()
    private let rimLayer = CAShapeLayer()
    private let figuresMaskLayer = CAShapeLayer()
    private let figuresGradientLayer = CAGradientLayer()
    private let backOrbitContainer = CALayer()
    private let frontOrbitContainer = CALayer()
    private var hasStartedAnimations = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
        startAnimationsIfNeeded()
        resumeAnimationsIfNeeded()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateLayout()
        applyColors()
        resumeAnimationsIfNeeded()
    }

    private func commonInit() {
        backgroundColor = .clear
        isUserInteractionEnabled = false

        layer.addSublayer(contentLayer)
        
        // 1. Back Orbits Container (under figures)
        contentLayer.addSublayer(backOrbitContainer)
        backOrbitContainer.addSublayer(detailRingLayer)
        backOrbitContainer.addSublayer(orbitGuideLayer)
        backOrbitContainer.addSublayer(backOrbitLayer)

        // 2. Main Figures (Flat)
        contentLayer.addSublayer(glowLayer)
        figuresGradientLayer.mask = figuresMaskLayer
        contentLayer.addSublayer(figuresGradientLayer)
        contentLayer.addSublayer(rimLayer)

        // 3. Front Orbits Container (over figures)
        contentLayer.addSublayer(frontOrbitContainer)
        frontOrbitContainer.addSublayer(frontOrbitLayer)

        glowLayer.opacity = 0.28
        glowLayer.lineWidth = 0
        glowLayer.shadowOpacity = 0

        detailRingLayer.fillColor = UIColor.clear.cgColor
        detailRingLayer.lineWidth = 1.2
        detailRingLayer.lineDashPattern = nil

        orbitGuideLayer.fillColor = UIColor.clear.cgColor
        orbitGuideLayer.lineWidth = 1.1
        orbitGuideLayer.lineDashPattern = [4, 16]

        backOrbitLayer.fillColor = UIColor.clear.cgColor
        backOrbitLayer.lineCap = .round
        backOrbitLayer.lineDashPattern = [11, 16]
        backOrbitLayer.lineWidth = 7
        backOrbitLayer.opacity = 0.48

        figuresMaskLayer.fillRule = .evenOdd

        rimLayer.fillColor = UIColor.clear.cgColor
        rimLayer.lineWidth = 1.8

        frontOrbitLayer.fillColor = UIColor.clear.cgColor
        frontOrbitLayer.lineCap = .round
        frontOrbitLayer.lineDashPattern = [11, 16]
        frontOrbitLayer.lineWidth = 9
        frontOrbitLayer.shadowColor = UIColor.black.cgColor
        frontOrbitLayer.shadowOffset = CGSize(width: 0, height: 12)
        frontOrbitLayer.shadowRadius = 14
        frontOrbitLayer.shadowOpacity = 0.22

        figuresGradientLayer.startPoint = CGPoint(x: 0.15, y: 0.1)
        figuresGradientLayer.endPoint = CGPoint(x: 0.85, y: 0.95)

        contentLayer.actions = [
            "position": NSNull(),
            "bounds": NSNull(),
            "transform": NSNull()
        ]
        backOrbitContainer.actions = contentLayer.actions
        frontOrbitContainer.actions = contentLayer.actions
    }

    private func updateLayout() {
        let side = min(bounds.width, bounds.height)
        let square = CGRect(
            x: (bounds.width - side) / 2,
            y: (bounds.height - side) / 2,
            width: side,
            height: side
        )

        contentLayer.frame = square
        figuresGradientLayer.frame = contentLayer.bounds
        let figuresPath = makeFiguresPath(in: contentLayer.bounds)
        let glowPath = makeGlowPath(in: contentLayer.bounds)
        let detailPath = makeDetailRingPath(in: contentLayer.bounds)
        let orbitGuidePath = makeOrbitGuidePath(in: contentLayer.bounds)
        let backOrbitPath = makeOrbitSegmentPath(in: contentLayer.bounds, startAngle: .pi * 1.04, endAngle: .pi * 1.76)
        let frontOrbitPath = makeOrbitSegmentPath(in: contentLayer.bounds, startAngle: .pi * 0.17, endAngle: .pi * 0.90)

        detailRingLayer.frame = contentLayer.bounds
        detailRingLayer.path = detailPath.cgPath

        orbitGuideLayer.frame = contentLayer.bounds
        orbitGuideLayer.path = orbitGuidePath.cgPath

        glowLayer.frame = contentLayer.bounds
        glowLayer.path = glowPath.cgPath
        glowLayer.shadowPath = glowPath.cgPath
        glowLayer.shadowRadius = side * 0.08
        glowLayer.shadowOffset = .zero
        glowLayer.shadowOpacity = traitCollection.userInterfaceStyle == .dark ? 0.30 : 0.18

        figuresMaskLayer.frame = contentLayer.bounds
        figuresMaskLayer.path = figuresPath.cgPath

        rimLayer.frame = contentLayer.bounds
        rimLayer.path = figuresPath.cgPath

        let perspective = makeOrbitPerspective()
        
        backOrbitContainer.frame = contentLayer.bounds
        backOrbitContainer.sublayerTransform = perspective
        
        frontOrbitContainer.frame = contentLayer.bounds
        frontOrbitContainer.sublayerTransform = perspective

        backOrbitLayer.frame = contentLayer.bounds
        backOrbitLayer.path = backOrbitPath.cgPath

        frontOrbitLayer.frame = contentLayer.bounds
        frontOrbitLayer.path = frontOrbitPath.cgPath

        applyColors()
    }

    private func applyColors() {
        let isDark = traitCollection.userInterfaceStyle == .dark

        if isDark {
            figuresGradientLayer.colors = [
                UIColor(red: 0.74, green: 0.84, blue: 0.93, alpha: 1).cgColor,
                AppTheme.accent.resolvedColor(with: traitCollection).cgColor
            ]
            glowLayer.fillColor = AppTheme.accent.resolvedColor(with: traitCollection).withAlphaComponent(0.92).cgColor
            detailRingLayer.strokeColor = UIColor.white.withAlphaComponent(0.06).cgColor
            orbitGuideLayer.strokeColor = UIColor.white.withAlphaComponent(0.08).cgColor
            backOrbitLayer.strokeColor = UIColor(red: 0.28, green: 0.39, blue: 0.47, alpha: 0.72).cgColor
            frontOrbitLayer.strokeColor = UIColor(red: 0.68, green: 0.82, blue: 0.92, alpha: 1).cgColor
            rimLayer.strokeColor = UIColor.white.withAlphaComponent(0.34).cgColor
            frontOrbitLayer.shadowOpacity = 0.30
            backOrbitLayer.opacity = 0.34
        } else {
            figuresGradientLayer.colors = [
                UIColor(red: 0.80, green: 0.89, blue: 0.96, alpha: 1).cgColor,
                AppTheme.accent.resolvedColor(with: traitCollection).cgColor
            ]
            glowLayer.fillColor = AppTheme.accent.resolvedColor(with: traitCollection).withAlphaComponent(0.72).cgColor
            detailRingLayer.strokeColor = UIColor.white.withAlphaComponent(0.12).cgColor
            orbitGuideLayer.strokeColor = UIColor(red: 0.62, green: 0.75, blue: 0.87, alpha: 0.28).cgColor
            backOrbitLayer.strokeColor = UIColor(red: 0.40, green: 0.56, blue: 0.68, alpha: 0.42).cgColor
            frontOrbitLayer.strokeColor = UIColor(red: 0.69, green: 0.82, blue: 0.93, alpha: 1).cgColor
            rimLayer.strokeColor = UIColor.white.withAlphaComponent(0.72).cgColor
            frontOrbitLayer.shadowOpacity = 0.18
            backOrbitLayer.opacity = 0.28
        }
    }

    private func startAnimationsIfNeeded() {
        guard !hasStartedAnimations else { return }
        hasStartedAnimations = true

        addContinuousAnimations(force: true)
    }

    func refreshAnimationState() {
        updateLayout()
        applyColors()
        resumeAnimationsIfNeeded()
    }

    private func resumeAnimationsIfNeeded() {
        guard hasStartedAnimations else { return }
        addContinuousAnimations(force: false)
    }

    private func addContinuousAnimations(force: Bool) {
        if force || backOrbitLayer.animation(forKey: "dashPhase") == nil {
            let backPhase = CABasicAnimation(keyPath: "lineDashPhase")
            backPhase.fromValue = 0
            backPhase.toValue = -54
            backPhase.duration = 4.2
            backPhase.repeatCount = .infinity
            backPhase.timingFunction = CAMediaTimingFunction(name: .linear)
            backOrbitLayer.add(backPhase, forKey: "dashPhase")
        }

        if force || frontOrbitLayer.animation(forKey: "frontDashPhase") == nil {
            let frontPhase = CABasicAnimation(keyPath: "lineDashPhase")
            frontPhase.fromValue = 0
            frontPhase.toValue = -54
            frontPhase.duration = 4.2
            frontPhase.repeatCount = .infinity
            frontPhase.timingFunction = CAMediaTimingFunction(name: .linear)
            frontOrbitLayer.add(frontPhase, forKey: "frontDashPhase")
        }

        if force || frontOrbitLayer.animation(forKey: "frontTint") == nil {
            let frontTintAnimation = CABasicAnimation(keyPath: "opacity")
            frontTintAnimation.fromValue = 0.72
            frontTintAnimation.toValue = 1.0
            frontTintAnimation.duration = 2.6
            frontTintAnimation.autoreverses = true
            frontTintAnimation.repeatCount = .infinity
            frontTintAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            frontOrbitLayer.add(frontTintAnimation, forKey: "frontTint")
        }

        if force || backOrbitLayer.animation(forKey: "backTint") == nil {
            let backTintAnimation = CABasicAnimation(keyPath: "opacity")
            backTintAnimation.fromValue = 0.12
            backTintAnimation.toValue = 0.34
            backTintAnimation.duration = 2.6
            backTintAnimation.autoreverses = true
            backTintAnimation.repeatCount = .infinity
            backTintAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            backOrbitLayer.add(backTintAnimation, forKey: "backTint")
        }

        if force || glowLayer.animation(forKey: "glowPulse") == nil {
            let glowPulse = CABasicAnimation(keyPath: "opacity")
            glowPulse.fromValue = 0.18
            glowPulse.toValue = 0.30
            glowPulse.duration = 3.2
            glowPulse.autoreverses = true
            glowPulse.repeatCount = .infinity
            glowPulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            glowLayer.add(glowPulse, forKey: "glowPulse")
        }
    }

    private func makeFiguresPath(in rect: CGRect) -> UIBezierPath {
        let width = rect.width
        let height = rect.height

        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + (width * x), y: rect.minY + (height * y))
        }

        let path = UIBezierPath()

        let leftHeadCenter = point(0.31, 0.34)
        path.append(UIBezierPath(
            arcCenter: leftHeadCenter,
            radius: width * 0.115,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        ))

        let leftBodyRect = CGRect(
            x: rect.minX + (width * 0.12),
            y: rect.minY + (height * 0.51),
            width: width * 0.31,
            height: height * 0.39
        )
        path.append(UIBezierPath(
            roundedRect: leftBodyRect,
            cornerRadius: leftBodyRect.width * 0.48
        ))

        let rightHeadCenter = point(0.62, 0.22)
        path.append(UIBezierPath(
            arcCenter: rightHeadCenter,
            radius: width * 0.16,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        ))

        let rightBodyRect = CGRect(
            x: rect.minX + (width * 0.43),
            y: rect.minY + (height * 0.41),
            width: width * 0.38,
            height: height * 0.50
        )
        path.append(UIBezierPath(
            roundedRect: rightBodyRect,
            cornerRadius: rightBodyRect.width * 0.5
        ))

        return path
    }

    private func makeGlowPath(in rect: CGRect) -> UIBezierPath {
        let glowRect = rect.insetBy(dx: rect.width * -0.03, dy: rect.height * -0.03)
        return makeFiguresPath(in: glowRect)
    }

    private func makeDetailRingPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        path.append(UIBezierPath(ovalIn: rect.insetBy(dx: rect.width * 0.13, dy: rect.height * 0.13)))
        path.append(UIBezierPath(ovalIn: rect.insetBy(dx: rect.width * 0.30, dy: rect.height * 0.30)))
        return path
    }

    private func makeOrbitGuidePath(in rect: CGRect, rotation: CGFloat = -.pi / 5.9) -> UIBezierPath {
        makeOrbitPath(in: rect, startAngle: 0, endAngle: .pi * 2, rotation: rotation)
    }

    private func makeOrbitSegmentPath(in rect: CGRect, startAngle: CGFloat, endAngle: CGFloat, rotation: CGFloat = -.pi / 5.9) -> UIBezierPath {
        makeOrbitPath(in: rect, startAngle: startAngle, endAngle: endAngle, rotation: rotation)
    }

    private func makeOrbitPath(in rect: CGRect, startAngle: CGFloat, endAngle: CGFloat, rotation: CGFloat = -.pi / 5.9) -> UIBezierPath {
        let width = rect.width
        let height = rect.height

        let orbitRect = CGRect(
            x: rect.minX + (width * 0.02),
            y: rect.minY + (height * 0.35),
            width: width * 0.96,
            height: height * 0.33
        )

        let path = UIBezierPath(ovalIn: orbitRect)
        let orbitCenter = CGPoint(x: orbitRect.midX, y: orbitRect.midY)

        let maskPath = UIBezierPath()
        maskPath.move(to: pointOnEllipse(in: orbitRect, angle: startAngle))
        maskPath.addArc(
            withCenter: orbitCenter,
            radius: orbitRect.width / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )

        let scaleY = orbitRect.height / orbitRect.width
        var ellipseTransform = CGAffineTransform.identity
        ellipseTransform = ellipseTransform.translatedBy(x: orbitCenter.x, y: orbitCenter.y)
        ellipseTransform = ellipseTransform.scaledBy(x: 1, y: scaleY)
        ellipseTransform = ellipseTransform.rotated(by: rotation)
        ellipseTransform = ellipseTransform.translatedBy(x: -orbitCenter.x, y: -orbitCenter.y)

        path.apply(ellipseTransform)
        maskPath.apply(ellipseTransform)

        let segmentPath = UIBezierPath()
        segmentPath.append(maskPath)
        return segmentPath
    }

    private func pointOnEllipse(in rect: CGRect, angle: CGFloat) -> CGPoint {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        return CGPoint(
            x: center.x + ((rect.width / 2) * cos(angle)),
            y: center.y + ((rect.width / 2) * sin(angle))
        )
    }

    private func makeOrbitPerspective() -> CATransform3D {
        var transform = CATransform3DIdentity
        transform.m34 = -1 / 700
        transform = CATransform3DRotate(transform, .pi / 10, 1, 0, 0)
        return transform
    }
}

extension UIViewController {
    func styleAuthBackButton(_ button: UIButton?) {
        guard let button else { return }

        let tint = UIColor { trait in trait.userInterfaceStyle == .dark ? .white : .black }
        let background = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.14) : .white
        }

        button.tintColor = tint
        button.backgroundColor = background
        button.layer.cornerRadius = 22
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor
        button.layer.shadowOpacity = 0
        button.layer.masksToBounds = true

        if var config = button.configuration {
            config.baseForegroundColor = tint
            config.baseBackgroundColor = background
            config.background.backgroundColor = background
            config.background.strokeColor = UIColor.white.withAlphaComponent(0.10)
            button.configuration = config
        }
    }

    func applyAuthSymbolTint() {
        let symbolTint = UIColor { trait in
            trait.userInterfaceStyle == .dark ? .white : UIColor(white: 0.33, alpha: 1)
        }

        view.recursiveSubviews().forEach { subview in
            if let imageView = subview as? UIImageView,
               let image = imageView.image,
               imageView.bounds.width <= 40 || imageView.bounds.height <= 40 {
                imageView.image = image.withRenderingMode(.alwaysTemplate)
                imageView.tintColor = symbolTint
            }

            if let button = subview as? UIButton,
               let currentImage = button.image(for: .normal),
               currentImage.renderingMode != .alwaysOriginal,
               button.bounds.width <= 50 || button.bounds.height <= 50 {
                button.setImage(currentImage.withRenderingMode(.alwaysTemplate), for: .normal)
                let usesSquareSymbol = button.configuration?.image == nil &&
                    button.title(for: .normal) == "Button" &&
                    button.bounds.width <= 36
                button.tintColor = usesSquareSymbol ? .white : symbolTint
            }
        }
    }

    func refreshAnimatedAuthLogoIfNeeded() {
        view.recursiveSubviews()
            .compactMap { $0 as? AnimatedAuthLogoView }
            .forEach { $0.refreshAnimationState() }
    }

    func hideAnimatedAuthLogoPlaceholderIfNeeded() {
        let imageViews = view.recursiveSubviews().compactMap { $0 as? UIImageView }
        let candidate = imageViews
            .filter { imageView in
                let frame = imageView.convert(imageView.bounds, to: view)
                return frame.width >= 100 &&
                    frame.height >= 100 &&
                    frame.minY < view.bounds.midY
            }
            .sorted { lhs, rhs in
                let lhsFrame = lhs.convert(lhs.bounds, to: view)
                let rhsFrame = rhs.convert(rhs.bounds, to: view)
                if lhsFrame.minY == rhsFrame.minY {
                    return (lhsFrame.width * lhsFrame.height) > (rhsFrame.width * rhsFrame.height)
                }
                return lhsFrame.minY < rhsFrame.minY
            }
            .first

        candidate?.isHidden = true
    }

    @discardableResult
    func installAnimatedAuthLogoIfNeeded(
        sizeMultiplier: CGFloat = 0.72,
        verticalOffset: CGFloat = -8
    ) -> Bool {
        let logoTag = 909_500

        if view.recursiveSubviews().contains(where: { $0.tag == logoTag }) {
            return true
        }

        let imageViews = view.recursiveSubviews().compactMap { $0 as? UIImageView }
        let candidate = imageViews
            .filter { imageView in
                let frame = imageView.convert(imageView.bounds, to: view)
                return frame.width >= 100 &&
                    frame.height >= 100 &&
                    frame.minY < view.bounds.midY
            }
            .sorted { lhs, rhs in
                let lhsFrame = lhs.convert(lhs.bounds, to: view)
                let rhsFrame = rhs.convert(rhs.bounds, to: view)
                if lhsFrame.minY == rhsFrame.minY {
                    return (lhsFrame.width * lhsFrame.height) > (rhsFrame.width * rhsFrame.height)
                }
                return lhsFrame.minY < rhsFrame.minY
            }
            .first

        guard let imageView = candidate, let superview = imageView.superview else {
            return false
        }

        let logoView = AnimatedAuthLogoView()
        logoView.tag = logoTag
        logoView.translatesAutoresizingMaskIntoConstraints = false
        superview.addSubview(logoView)

        let frame = imageView.convert(imageView.bounds, to: superview)
        let side = max(frame.width, frame.height) * sizeMultiplier

        NSLayoutConstraint.activate([
            logoView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            logoView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor, constant: verticalOffset),
            logoView.widthAnchor.constraint(equalToConstant: side),
            logoView.heightAnchor.constraint(equalToConstant: side)
        ])

        imageView.isHidden = true
        superview.bringSubviewToFront(logoView)
        return true
    }
}

private extension UIView {
    func recursiveSubviews() -> [UIView] {
        subviews + subviews.flatMap { $0.recursiveSubviews() }
    }
}

enum PrivacyPolicySupport {
    static let url = URL(string: "https://icohort.netlify.app/")!

    static func present(from viewController: UIViewController) {
        let safari = SFSafariViewController(url: url)
        safari.preferredControlTintColor = AppTheme.buttonColor
        if #available(iOS 15.0, *) {
            safari.preferredBarTintColor = .systemBackground
        }
        viewController.present(safari, animated: true)
    }

    static func stylePolicyButton(_ button: UIButton,
                                  title: String,
                                  traitCollection: UITraitCollection,
                                  showsIcon: Bool = false,
                                  horizontalInset: CGFloat = 20) {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = showsIcon ? UIImage(systemName: "lock.shield") : nil
        config.imagePadding = showsIcon ? 10 : 0
        config.baseForegroundColor = .label
        config.background.backgroundColor = .clear
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: horizontalInset, bottom: 0, trailing: horizontalInset)
        config.titleAlignment = .leading
        button.configuration = config
        button.contentHorizontalAlignment = .leading
        button.tintColor = .label
        button.setTitleColor(.label, for: .normal)
    }

    static func styleConsentCheckbox(_ button: UIButton, isChecked: Bool, traitCollection: UITraitCollection) {
        var config = UIButton.Configuration.plain()
        config.contentInsets = .zero
        config.baseForegroundColor = isChecked ? .white : .clear
        config.image = isChecked ? UIImage(systemName: "checkmark") : nil
        button.configuration = config
        button.backgroundColor = isChecked ? AppTheme.buttonColor : .clear
        button.layer.cornerRadius = 6
        button.layer.borderWidth = 2
        let borderColor: UIColor = isChecked
            ? AppTheme.buttonColor
            : (traitCollection.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.72) : UIColor.black.withAlphaComponent(0.35))
        button.layer.borderColor = borderColor.cgColor
        button.tintColor = .white
    }
}
