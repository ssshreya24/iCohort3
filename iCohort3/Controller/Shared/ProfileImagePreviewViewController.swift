import UIKit

final class ProfileImagePreviewViewController: UIViewController {
    private let image: UIImage
    private let circularImageContainer = UIView()
    private let imageView = UIImageView()
    private let closeButton = UIButton(type: .system)

    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.94)

        circularImageContainer.translatesAutoresizingMaskIntoConstraints = false
        circularImageContainer.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        circularImageContainer.layer.borderWidth = 1
        circularImageContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
        view.addSubview(circularImageContainer)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = image
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        circularImageContainer.addSubview(imageView)

        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "xmark")
        config.baseForegroundColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.configuration = config
        closeButton.addTarget(self, action: #selector(dismissPreview), for: .touchUpInside)
        view.addSubview(closeButton)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissPreview))
        view.addGestureRecognizer(tap)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

            circularImageContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            circularImageContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            circularImageContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.72),
            circularImageContainer.heightAnchor.constraint(equalTo: circularImageContainer.widthAnchor),

            imageView.topAnchor.constraint(equalTo: circularImageContainer.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: circularImageContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: circularImageContainer.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: circularImageContainer.bottomAnchor)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        circularImageContainer.layer.cornerRadius = circularImageContainer.bounds.width / 2
        circularImageContainer.layer.masksToBounds = true
    }

    @objc private func dismissPreview() {
        dismiss(animated: true)
    }
}
