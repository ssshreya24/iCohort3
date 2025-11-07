//
//  SignUpViewController.swift
//  iCohort3
//
//  Created by Shreya on 07/11/25.
//

import UIKit

class SignUpViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackButton()

        // Do any additional setup after loading the view.
    }
    
    private func setupBackButton() {
            let backButton = UIButton(type: .system)
            let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
            let image = UIImage(systemName: "chevron.left", withConfiguration: config)
            backButton.setImage(image, for: .normal)
            
            backButton.tintColor = UIColor.systemBlue
            backButton.backgroundColor = UIColor(red: 196/255, green: 220/255, blue: 247/255, alpha: 1.0)
            backButton.layer.cornerRadius = 20
            backButton.layer.masksToBounds = true
            backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
            view.addSubview(backButton)
            backButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
                backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                backButton.widthAnchor.constraint(equalToConstant: 40),
                backButton.heightAnchor.constraint(equalToConstant: 40)
            ])
        }

        @objc private func backTapped() {
            dismiss(animated: true, completion: nil)
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */


