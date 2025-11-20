//
//  AttachmentViewerViewController.swift
//  iCohort3
//
//  Created by user@51 on 20/11/25.
//

import UIKit

class AttachmentViewerViewController: UIViewController {
    
    private var attachments: [UIImage]
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
    
    init(attachments: [UIImage], startIndex: Int = 0) {
        self.attachments = attachments
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
            let imageScrollView = UIScrollView()
            imageScrollView.frame = CGRect(
                x: view.bounds.width * CGFloat(index),
                y: 0,
                width: view.bounds.width,
                height: view.bounds.height
            )
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
            scrollView.addSubview(imageScrollView)
            
            // Add double tap gesture for zoom
            let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
            doubleTap.numberOfTapsRequired = 2
            imageView.addGestureRecognizer(doubleTap)
        }
        
        // Scroll to initial index
        scrollView.contentOffset = CGPoint(x: view.bounds.width * CGFloat(currentIndex), y: 0)
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
        let currentImage = attachments[currentIndex]
        let activityVC = UIActivityViewController(activityItems: [currentImage], applicationActivities: nil)
        
        // For iPad
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = shareButton
            popover.sourceRect = shareButton.bounds
        }
        
        present(activityVC, animated: true)
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
