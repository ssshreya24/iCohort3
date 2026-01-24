//
//  LinkAttachmentView.swift
//  iCohort3
//
//  Created by user@51 on 24/01/26.
//

import UIKit

class LinkAttachmentView: UIView {
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .systemBlue
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        iv.image = UIImage(systemName: "link", withConfiguration: config)
        return iv
    }()
    
    private let linkLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemBlue
        label.numberOfLines = 2
        return label
    }()
    
    private let openButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Open", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        return button
    }()
    
    var linkURL: String?
    var onTap: ((String) -> Void)?
    
    init() {
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(linkLabel)
        containerView.addSubview(openButton)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            linkLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            linkLabel.trailingAnchor.constraint(equalTo: openButton.leadingAnchor, constant: -8),
            linkLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            openButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            openButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            openButton.widthAnchor.constraint(equalToConstant: 60),
            openButton.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        openButton.addTarget(self, action: #selector(openLinkTapped), for: .touchUpInside)
        
        // Add tap gesture to entire container
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openLinkTapped))
        containerView.addGestureRecognizer(tapGesture)
    }
    
    func configure(with url: String) {
        self.linkURL = url
        
        // Display shortened URL
        if let urlObj = URL(string: url) {
            linkLabel.text = urlObj.host ?? url
        } else {
            linkLabel.text = url
        }
    }
    
    @objc private func openLinkTapped() {
        guard let urlString = linkURL,
              let url = URL(string: urlString) else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:])
        }
        
        onTap?(urlString)
    }
}
