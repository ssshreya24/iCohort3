import UIKit

enum AdminUIStyle {
    static let backgroundColor = UIColor.systemBackground
    static let accentColor = AppTheme.accent

    static func styleScreenBackground(_ view: UIView) {
        AppTheme.applyScreenBackground(to: view)
    }

    static func updateScreenBackgroundLayout(for view: UIView) {
        AppTheme.applyScreenBackground(to: view)
    }

    static func makeFloatingBackButton(target: Any?, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = AppTheme.accent
        AppTheme.styleFloatingControl(button, cornerRadius: 22)
        button.addTarget(target, action: action, for: .touchUpInside)
        return button
    }

    static func styleCard(_ view: UIView, cornerRadius: CGFloat = 16) {
        AppTheme.styleCard(view, cornerRadius: cornerRadius)
    }

    static func styleCompactActionButton(_ button: UIButton, systemImage: String) {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: systemImage)
        config.baseForegroundColor = AppTheme.accent
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        button.configuration = config
        AppTheme.styleFloatingControl(button, cornerRadius: 18)
    }

    static func styleSearchBar(_ searchBar: UISearchBar) {
        searchBar.searchBarStyle = .minimal
        searchBar.searchTextField.backgroundColor = AppTheme.floatingBackground
        searchBar.searchTextField.textColor = .label
        searchBar.searchTextField.layer.cornerRadius = 14
        searchBar.searchTextField.clipsToBounds = true
    }
}
