import UIKit

enum AdminUIStyle {
    private static let gradientLayerName = "AdminUIStyleGradientLayer"
    static let backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 245/255, alpha: 1.0)
    static let accentColor = UIColor(red: 0x77/255, green: 0x9C/255, blue: 0xB3/255, alpha: 1)

    static func styleScreenBackground(_ view: UIView) {
        view.backgroundColor = backgroundColor
        let gradientLayer: CAGradientLayer

        if let existing = view.layer.sublayers?.first(where: { $0.name == gradientLayerName }) as? CAGradientLayer {
            gradientLayer = existing
        } else {
            gradientLayer = CAGradientLayer()
            gradientLayer.name = gradientLayerName
            gradientLayer.colors = [
                UIColor(red: 0.78, green: 0.88, blue: 0.95, alpha: 1).cgColor,
                UIColor(white: 0.95, alpha: 1).cgColor
            ]
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
            view.layer.insertSublayer(gradientLayer, at: 0)
        }

        gradientLayer.frame = view.bounds
    }

    static func updateScreenBackgroundLayout(for view: UIView) {
        guard let gradientLayer = view.layer.sublayers?.first(where: { $0.name == gradientLayerName }) as? CAGradientLayer else {
            styleScreenBackground(view)
            return
        }
        gradientLayer.frame = view.bounds
    }

    static func makeFloatingBackButton(target: Any?, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .black
        button.backgroundColor = .white
        button.layer.cornerRadius = 22
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.08
        button.addTarget(target, action: action, for: .touchUpInside)
        return button
    }

    static func styleCard(_ view: UIView, cornerRadius: CGFloat = 16) {
        view.backgroundColor = .white
        view.layer.cornerRadius = cornerRadius
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        view.layer.shadowOpacity = 0.06
    }

    static func styleCompactActionButton(_ button: UIButton, systemImage: String) {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: systemImage)
        config.baseForegroundColor = UIColor(red: 0.20, green: 0.31, blue: 0.43, alpha: 1)
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        button.configuration = config
        button.backgroundColor = UIColor.white.withAlphaComponent(0.96)
        button.layer.cornerRadius = 18
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.08
    }

    static func styleSearchBar(_ searchBar: UISearchBar) {
        searchBar.searchBarStyle = .minimal
        searchBar.searchTextField.backgroundColor = UIColor.white.withAlphaComponent(0.96)
        searchBar.searchTextField.layer.cornerRadius = 14
        searchBar.searchTextField.clipsToBounds = true
    }
}
