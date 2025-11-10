//
//  SignUpViewController.swift
//  iCohort3
//
//  Created by Shreya on 07/11/25.
//

import UIKit

class SignUpViewController: UIViewController {
    @IBOutlet weak var fullNameContainer: UIView!
    @IBOutlet weak var emailContainer: UIView!
    @IBOutlet weak var regContainer: UIView!
    @IBOutlet weak var passwordContainer: UIView!
    @IBOutlet weak var confirmContainer: UIView!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var fullNameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var regField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmField: UITextField!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackButton()
        roundViews()
        setupPlaceholders()
        
        // Do any additional setup after loading the view.
    }
    func setupPlaceholders() {
        fullNameField.placeholder = "Enter your full name"
        emailField.placeholder = "Enter your email address"
        regField.placeholder = "Enter your registration number"
        passwordField.placeholder = "Enter your password"
        confirmField.placeholder = "Confirm your password"
    }
    func roundViews() {
        let containers = [fullNameContainer, emailContainer, regContainer, passwordContainer, confirmContainer]
        
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
        if let navigationController = self.navigationController {
                navigationController.popViewController(animated: true)
            } else {
                dismiss(animated: true, completion: nil)
            }
    }
    @IBAction func signUpTapped(_ sender: UIButton) {
        view.endEditing(true) 
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
           if let loginVC = storyboard.instantiateViewController(withIdentifier: "SLoginVC") as? LoginViewController {
               let transition = CATransition()
               transition.duration = 0.35
               transition.type = .push
               transition.subtype = .fromLeft
               transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
               navigationController?.view.layer.add(transition, forKey: kCATransition)
               navigationController?.pushViewController(loginVC, animated: false)
           }
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


