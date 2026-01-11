//
//  MSignUpViewController.swift
//  iCohort3
//
//  Created by user@51 on 13/11/25.
//

import UIKit

class MSignUpViewController: UIViewController {

    @IBOutlet weak var fullNameContainer: UIView!
    @IBOutlet weak var emailContainer: UIView!

    @IBOutlet weak var employeeField: UITextField!
    @IBOutlet weak var employeeView: UIView!
    @IBOutlet weak var designationField: UITextField!
    @IBOutlet weak var designationView: UIView!
    @IBOutlet weak var passwordContainer: UIView!
    @IBOutlet weak var confirmContainer: UIView!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var fullNameField: UITextField!
    @IBOutlet weak var emailField: UITextField!

    @IBOutlet weak var departmentField: UITextField!
    @IBOutlet weak var departmentView: UIView!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmField: UITextField!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackButton()
        roundViews()
        
        // Do any additional setup after loading the view.
    }
    
    func roundViews() {
        let containers = [fullNameContainer, emailContainer, designationView,employeeView,departmentView, passwordContainer, confirmContainer]
        
        for view in containers {
            view?.layer.cornerRadius = 20
            view?.layer.borderWidth  = 0
            view?.layer.borderColor  = UIColor.systemGray4.cgColor
            view?.layer.masksToBounds = true
            view?.backgroundColor    = .white
        }
        
        signUpButton.layer.cornerRadius = 20
        signUpButton.layer.masksToBounds = true
        signUpButton.backgroundColor = UIColor(named: "Primary")
        
        
        signUpButton.layer.shadowColor = UIColor.black.cgColor
        signUpButton.layer.shadowOpacity = 0.15
        signUpButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        signUpButton.layer.shadowRadius = 8
        signUpButton.layer.masksToBounds = false
    }
    
    private func setupBackButton() {
        let backButton = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        let image = UIImage(systemName: "chevron.left", withConfiguration: config)
        backButton.setImage(image, for: .normal)
        
        backButton.tintColor = UIColor.black
        backButton.backgroundColor = UIColor.white
        backButton.layer.cornerRadius = 22
        backButton.layer.masksToBounds = true
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc private func backTapped() {
        if let navigationController = self.navigationController {
                navigationController.popViewController(animated: true)
            } else {
                dismiss(animated: true, completion: nil)
            }
    }
    
    @IBAction func signUpTapped(_ sender: UIButton) {
        view.endEditing(true)

        navigationController?.popViewController(animated: false)
    }

}
