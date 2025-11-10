//
//  forgotPasswordViewController.swift
//  iCohort3
//
//  Created by user@56 on 07/11/25.
//

import UIKit

class forgotPasswordViewController: UIViewController {

 
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var confirmPassword: UIView!
    @IBOutlet weak var passwordContainer: UIView!
    
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var backButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
                setupUI()
        setupPlaceholders()
        
        confirmButton.tintColor = UIColor(red: 0x77/255.0, green: 0x9C/255.0, blue: 0xB3/255.0, alpha: 1.0)
        backButton.tintColor = .white
       
          backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)

                // Add button action
                backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        

            }
            
   
    func setupPlaceholders() {
        newPasswordTextField.placeholder = "Enter the new password"
        confirmPasswordTextField.placeholder = "Confirm the new password"
        newPasswordTextField.textColor = .black
            confirmPasswordTextField.textColor = .black
            
            // Optional: make password dots visible
            newPasswordTextField.isSecureTextEntry = true
            confirmPasswordTextField.isSecureTextEntry = true
       
    }

   
            // MARK: - UI Setup
            private func setupUI() {
                // Rounded corners for the containers and button
                passwordContainer.layer.cornerRadius = 20
                passwordContainer.layer.masksToBounds = true
                passwordContainer.backgroundColor = .white
                
                confirmPassword.layer.cornerRadius = 20
                confirmPassword.layer.masksToBounds = true
                
                
                confirmButton.layer.cornerRadius = 20
                confirmButton.layer.masksToBounds = true
            }
    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let loginVC = storyboard.instantiateViewController(withIdentifier: "SLoginVC") as? LoginViewController {
                let navController = UINavigationController(rootViewController: loginVC)
                navController.modalPresentationStyle = .fullScreen
                self.view.window?.rootViewController = navController
                self.view.window?.makeKeyAndVisible()
            }
    }

            // MARK: - Actions
            @objc private func backTapped() {
                // Dismiss the current screen
                self.dismiss(animated: true, completion: nil)
                // If you’re using navigation controller instead:
                // self.navigationController?.popViewController(animated: true)
            }

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */


