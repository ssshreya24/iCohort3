import UIKit

class TaskSectionHeaderView: UICollectionReusableView {
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let chevronImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.down")
        iv.tintColor = .systemGray
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    var toggleAction: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
        addSubview(titleLabel)
        addSubview(chevronImageView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(headerTapped))
        addGestureRecognizer(tap)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            chevronImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            chevronImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 20),
            chevronImageView.heightAnchor.constraint(equalToConstant: 20),
            chevronImageView.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8)
        ])
    }
    
    @objc private func headerTapped() {
        toggleAction?()
    }
    
    func configure(title: String, isCollapsed: Bool) {
        titleLabel.text = title
        UIView.animate(withDuration: 0.3) {
            self.chevronImageView.transform = isCollapsed ? CGAffineTransform(rotationAngle: -.pi / 2) : .identity
        }
    }
}
