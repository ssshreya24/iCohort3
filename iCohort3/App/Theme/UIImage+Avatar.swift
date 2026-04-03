import UIKit

extension UIImage {
    static func generateAvatar(
        initials: String,
        font: UIFont = UIFont.systemFont(ofSize: 24, weight: .semibold),
        textColor: UIColor = .white,
        backgroundColor: UIColor = AppTheme.accent,
        size: CGSize = CGSize(width: 80, height: 80)
    ) -> UIImage? {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // Draw solid background
        context.setFillColor(backgroundColor.cgColor)
        context.fillEllipse(in: rect)

        // Draw text
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]

        let upperInitials = initials.prefix(1).uppercased()
        let textSize = (upperInitials as NSString).size(withAttributes: textAttributes)

        let textRect = CGRect(
            x: (size.width - textSize.width) / 2.0,
            y: (size.height - textSize.height) / 2.0,
            width: textSize.width,
            height: textSize.height
        )

        (upperInitials as NSString).draw(in: textRect, withAttributes: textAttributes)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }
}
