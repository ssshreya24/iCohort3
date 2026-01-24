import UIKit

class AttachmentViewerViewController: UIViewController {
    
    private var attachments: [UIImage]
    private var attachmentFilenames: [String] // Add filenames to detect links
    private var currentIndex: Int = 0
    
    // UI Elements
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.isPagingEnabled = true
        sv.showsHorizontalScrollIndicator = false
        return sv
    }()
    
    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.translatesAutoresizingMaskIntoConstraints = false
        pc.currentPageIndicatorTintColor = .white
        pc.pageIndicatorTintColor = .lightGray
        return pc
    }()
    
    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        btn.layer.cornerRadius = 20
        btn.clipsToBounds = true
        return btn
    }()
    
    private let counterLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.textColor = .white
        lbl.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        lbl.textAlignment = .center
        lbl.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        lbl.layer.cornerRadius = 15
        lbl.clipsToBounds = true
        return lbl
    }()
    
    private let shareButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        btn.layer.cornerRadius = 20
        btn.clipsToBounds = true
        return btn
    }()
    
    // Update initializer to accept filenames
    init(attachments: [UIImage], attachmentFilenames: [String] = [], startIndex: Int = 0) {
        self.attachments = attachments
        self.attachmentFilenames = attachmentFilenames
        self.currentIndex = startIndex
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        setupUI()
        setupAttachments()
        updateCounter()
    }
    
    private func setupUI() {
        // Add subviews
        view.addSubview(scrollView)
        view.addSubview(closeButton)
        view.addSubview(counterLabel)
        view.addSubview(shareButton)
        
        if attachments.count > 1 {
            view.addSubview(pageControl)
            pageControl.numberOfPages = attachments.count
            pageControl.currentPage = currentIndex
        }
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Close button
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Counter label
            counterLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            counterLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            counterLabel.heightAnchor.constraint(equalToConstant: 40),
            counterLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            
            // Share button
            shareButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            shareButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            shareButton.widthAnchor.constraint(equalToConstant: 40),
            shareButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        if attachments.count > 1 {
            NSLayoutConstraint.activate([
                pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        }
        
        // Add actions
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        
        scrollView.delegate = self
    }
    
    private func setupAttachments() {
        let contentWidth = view.bounds.width * CGFloat(attachments.count)
        scrollView.contentSize = CGSize(width: contentWidth, height: view.bounds.height)
        
        for (index, image) in attachments.enumerated() {
            let containerView = UIView()
            containerView.frame = CGRect(
                x: view.bounds.width * CGFloat(index),
                y: 0,
                width: view.bounds.width,
                height: view.bounds.height
            )
            containerView.backgroundColor = .black
            
            // Check if this is a link attachment
            let filename = index < attachmentFilenames.count ? attachmentFilenames[index] : ""
            let isLink = filename.hasPrefix("http://") || filename.hasPrefix("https://")
            
            if isLink {
                // Create link view
                let linkView = createLinkView(url: filename, in: containerView)
                containerView.addSubview(linkView)
                
                // Add constraints for linkView in containerView
                NSLayoutConstraint.activate([
                    linkView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                    linkView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                    linkView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 40),
                    linkView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -40)
                ])
            } else {
                // Create image scroll view for zooming
                let imageScrollView = UIScrollView()
                imageScrollView.frame = containerView.bounds
                imageScrollView.delegate = self
                imageScrollView.minimumZoomScale = 1.0
                imageScrollView.maximumZoomScale = 4.0
                imageScrollView.showsVerticalScrollIndicator = false
                imageScrollView.showsHorizontalScrollIndicator = false
                
                let imageView = UIImageView(image: image)
                imageView.contentMode = .scaleAspectFit
                imageView.frame = imageScrollView.bounds
                imageView.isUserInteractionEnabled = true
                imageView.tag = 100 + index
                
                imageScrollView.addSubview(imageView)
                containerView.addSubview(imageScrollView)
                
                // Add double tap gesture for zoom
                let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
                doubleTap.numberOfTapsRequired = 2
                imageView.addGestureRecognizer(doubleTap)
            }
            
            scrollView.addSubview(containerView)
        }
        
        // Scroll to initial index
        scrollView.contentOffset = CGPoint(x: view.bounds.width * CGFloat(currentIndex), y: 0)
    }
    
    private func createLinkView(url: String, in container: UIView) -> UIView {
        let linkContainerView = UIView()
        linkContainerView.translatesAutoresizingMaskIntoConstraints = false
        linkContainerView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
        linkContainerView.layer.cornerRadius = 20
        
        // Link icon
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .systemBlue
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 60, weight: .regular)
        iconImageView.image = UIImage(systemName: "link.circle.fill", withConfiguration: iconConfig)
        
        // URL label
        let urlLabel = UILabel()
        urlLabel.translatesAutoresizingMaskIntoConstraints = false
        if let urlObj = URL(string: url) {
            urlLabel.text = urlObj.host ?? url
        } else {
            urlLabel.text = url
        }
        urlLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        urlLabel.textColor = .white
        urlLabel.textAlignment = .center
        urlLabel.numberOfLines = 0
        
        // Full URL label
        let fullURLLabel = UILabel()
        fullURLLabel.translatesAutoresizingMaskIntoConstraints = false
        fullURLLabel.text = url
        fullURLLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        fullURLLabel.textColor = .lightGray
        fullURLLabel.textAlignment = .center
        fullURLLabel.numberOfLines = 0
        
        // Open button
        let openButton = UIButton(type: .system)
        openButton.translatesAutoresizingMaskIntoConstraints = false
        openButton.setTitle("Open Link", for: .normal)
        openButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        openButton.backgroundColor = .systemBlue
        openButton.setTitleColor(.white, for: .normal)
        openButton.layer.cornerRadius = 12
        openButton.addTarget(self, action: #selector(openLinkTapped(_:)), for: .touchUpInside)
        
        // Add subviews to linkContainerView
        linkContainerView.addSubview(iconImageView)
        linkContainerView.addSubview(urlLabel)
        linkContainerView.addSubview(fullURLLabel)
        linkContainerView.addSubview(openButton)
        
        // Store URL in button's accessibilityIdentifier
        openButton.accessibilityIdentifier = url
        
        // Set up internal constraints for linkContainerView's subviews
        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: linkContainerView.topAnchor, constant: 40),
            iconImageView.centerXAnchor.constraint(equalTo: linkContainerView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 80),
            iconImageView.heightAnchor.constraint(equalToConstant: 80),
            
            urlLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 24),
            urlLabel.leadingAnchor.constraint(equalTo: linkContainerView.leadingAnchor, constant: 20),
            urlLabel.trailingAnchor.constraint(equalTo: linkContainerView.trailingAnchor, constant: -20),
            
            fullURLLabel.topAnchor.constraint(equalTo: urlLabel.bottomAnchor, constant: 12),
            fullURLLabel.leadingAnchor.constraint(equalTo: linkContainerView.leadingAnchor, constant: 20),
            fullURLLabel.trailingAnchor.constraint(equalTo: linkContainerView.trailingAnchor, constant: -20),
            
            openButton.topAnchor.constraint(equalTo: fullURLLabel.bottomAnchor, constant: 32),
            openButton.centerXAnchor.constraint(equalTo: linkContainerView.centerXAnchor),
            openButton.widthAnchor.constraint(equalToConstant: 200),
            openButton.heightAnchor.constraint(equalToConstant: 50),
            openButton.bottomAnchor.constraint(equalTo: linkContainerView.bottomAnchor, constant: -40)
        ])
        
        return linkContainerView
    }
    
    @objc private func openLinkTapped(_ sender: UIButton) {
        guard let urlString = sender.accessibilityIdentifier,
              let url = URL(string: urlString) else {
            print("⚠️ Invalid URL")
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    print("✅ Opened URL: \(urlString)")
                } else {
                    print("❌ Failed to open URL: \(urlString)")
                }
            }
        } else {
            let alert = UIAlertController(
                title: "Cannot Open Link",
                message: "This link cannot be opened.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard let imageView = gesture.view as? UIImageView,
              let scrollView = imageView.superview as? UIScrollView else { return }
        
        if scrollView.zoomScale > 1.0 {
            scrollView.setZoomScale(1.0, animated: true)
        } else {
            let point = gesture.location(in: imageView)
            let zoomRect = CGRect(x: point.x - 50, y: point.y - 50, width: 100, height: 100)
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
    
    private func updateCounter() {
        if attachments.count > 1 {
            counterLabel.text = "\(currentIndex + 1) / \(attachments.count)"
        } else {
            counterLabel.text = "1 / 1"
        }
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func shareTapped() {
        let filename = currentIndex < attachmentFilenames.count ? attachmentFilenames[currentIndex] : ""
        let isLink = filename.hasPrefix("http://") || filename.hasPrefix("https://")
        
        if isLink {
            // Share the URL
            guard let url = URL(string: filename) else { return }
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = shareButton
                popover.sourceRect = shareButton.bounds
            }
            
            present(activityVC, animated: true)
        } else {
            // Share the image
            let currentImage = attachments[currentIndex]
            let activityVC = UIActivityViewController(activityItems: [currentImage], applicationActivities: nil)
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = shareButton
                popover.sourceRect = shareButton.bounds
            }
            
            present(activityVC, animated: true)
        }
    }
}

// MARK: - UIScrollViewDelegate
extension AttachmentViewerViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.scrollView {
            let pageIndex = Int(round(scrollView.contentOffset.x / view.bounds.width))
            if pageIndex != currentIndex && pageIndex >= 0 && pageIndex < attachments.count {
                currentIndex = pageIndex
                updateCounter()
                if attachments.count > 1 {
                    pageControl.currentPage = currentIndex
                }
            }
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if scrollView != self.scrollView {
            return scrollView.subviews.first
        }
        return nil
    }
}
