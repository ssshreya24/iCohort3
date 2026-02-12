//
//  OTPViewController.swift
//  iCohort3
//
//  ✅ Updated to verify OTP from custom password_reset_otps table
//  ✅ Works with custom OTP system (not Supabase Auth)
//  ✅ Beautiful, cute UI matching your design
//

import UIKit

class OTPViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var otpStack: UIStackView!
    @IBOutlet weak var confirmButton: UIButton!
    
    private var otpTextFields: [UITextField] = []
    private var loadingIndicator: UIActivityIndicatorView?
    private let numberOfDigits = 6

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupOTPFields()
        backButton.tintColor = .white
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func setupUI() {
        // Set button color to match app theme
        confirmButton.backgroundColor = UIColor(red: 0x77/255, green: 0x9C/255, blue: 0xB3/255, alpha: 1)
        confirmButton.layer.cornerRadius = 20
        confirmButton.layer.masksToBounds = true
        
        // Add shadow to button
        confirmButton.layer.shadowColor = UIColor.black.cgColor
        confirmButton.layer.shadowOpacity = 0.15
        confirmButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        confirmButton.layer.shadowRadius = 8
        confirmButton.layer.masksToBounds = false
    }
    
    private func setupOTPFields() {
        // Clear existing array
        otpTextFields.removeAll()
        
        print("📝 Setting up OTP fields...")
        
        // Remove all existing subviews from stack
        otpStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Configure stack view
        otpStack.axis = .horizontal
        otpStack.distribution = .fillEqually
        otpStack.spacing = 12  // Space between boxes
        otpStack.alignment = .center
        
        // Create text fields (cute small boxes like in your image)
        for i in 0..<numberOfDigits {
            let containerView = UIView()
            containerView.backgroundColor = .white
            containerView.layer.cornerRadius = 10
            containerView.layer.borderWidth = 1.5
            containerView.layer.borderColor = UIColor(red: 0xD1/255, green: 0xD5/255, blue: 0xDB/255, alpha: 1).cgColor
            
            let textField = UITextField()
            configureTextField(textField)
            
            containerView.addSubview(textField)
            textField.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                textField.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                textField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                textField.widthAnchor.constraint(equalTo: containerView.widthAnchor),
                textField.heightAnchor.constraint(equalTo: containerView.heightAnchor)
            ])
            
            otpStack.addArrangedSubview(containerView)
            otpTextFields.append(textField)
            
            // ✅ Set constraints to match your cute design (smaller boxes)
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.widthAnchor.constraint(equalToConstant: 45).isActive = true
            containerView.heightAnchor.constraint(equalToConstant: 45).isActive = true
            
            print("✅ Created text field \(i + 1)")
        }
        
        print("📝 Total OTP text fields configured: \(otpTextFields.count)")
        
        // Focus on first field
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.otpTextFields.first?.becomeFirstResponder()
        }
    }
    
    private func configureTextField(_ textField: UITextField) {
        textField.delegate = self
        textField.keyboardType = .numberPad
        textField.textAlignment = .center
        textField.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        textField.text = ""
        textField.backgroundColor = .clear
        textField.textColor = UIColor(red: 0x1F/255, green: 0x29/255, blue: 0x37/255, alpha: 1)
        textField.tintColor = UIColor(red: 0x77/255, green: 0x9C/255, blue: 0xB3/255, alpha: 1)
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        // Move to next field when a digit is entered
        if let text = textField.text, text.count == 1 {
            if let index = otpTextFields.firstIndex(of: textField), index < otpTextFields.count - 1 {
                otpTextFields[index + 1].becomeFirstResponder()
            } else {
                textField.resignFirstResponder()
            }
        }
    }

    @IBAction func backButtonTapped(_ sender: UIButton) {
        print("OTP back tapped")
        
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        print("Confirm button tapped")
        
        // Collect OTP from text fields
        var enteredOTP = ""
        for textField in otpTextFields {
            if let text = textField.text, !text.isEmpty {
                enteredOTP += text
            }
        }
        
        print("📝 Collected OTP: '\(enteredOTP)'")
        
        // Validate OTP length
        guard enteredOTP.count == numberOfDigits else {
            showAlert(title: "Invalid OTP", message: "Please enter the complete \(numberOfDigits)-digit OTP.")
            return
        }
        
        // Validate OTP contains only numbers
        guard enteredOTP.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil else {
            showAlert(title: "Invalid OTP", message: "OTP should contain only numbers")
            return
        }
        
        // Get email from UserDefaults
        guard let email = UserDefaults.standard.string(forKey: "forgot_password_email") else {
            showAlert(title: "Error", message: "Session expired. Please start the process again.")
            return
        }
        
        // Disable button and show loading
        confirmButton.isEnabled = false
        showLoadingIndicator()
        
        // Verify OTP
        verifyOTPAndNavigate(email: email, otp: enteredOTP)
    }
    
    private func verifyOTPAndNavigate(email: String, otp: String) {
        Task {
            do {
                try await SupabaseManager.shared.verifyOTPForPasswordReset(email: email, otp: otp)
                
                await MainActor.run {
                    hideLoadingIndicator()
                    confirmButton.isEnabled = true
                    
                    let forgotVC = forgotPasswordViewController(nibName: "forgotPasswordViewController", bundle: nil)
                    
                    if let nav = navigationController {
                        nav.pushViewController(forgotVC, animated: true)
                    } else {
                        forgotVC.modalPresentationStyle = .fullScreen
                        present(forgotVC, animated: true, completion: nil)
                    }
                }
                
            } catch {
                await MainActor.run {
                    hideLoadingIndicator()
                    confirmButton.isEnabled = true
                    
                    let errorMessage: String
                    if error.localizedDescription.contains("expired") {
                        errorMessage = "The OTP has expired. Please request a new one."
                    } else if error.localizedDescription.contains("Invalid") {
                        errorMessage = "Invalid OTP. Please check and try again."
                    } else {
                        errorMessage = "OTP verification failed. Please try again."
                    }
                    
                    showAlert(title: "Verification Failed", message: errorMessage)
                    
                    // Clear text fields
                    for textField in otpTextFields {
                        textField.text = ""
                    }
                    otpTextFields.first?.becomeFirstResponder()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func showLoadingIndicator() {
        hideLoadingIndicator()
        
        DispatchQueue.main.async {
            let indicator = UIActivityIndicatorView(style: .large)
            indicator.color = UIColor(red: 0x77/255, green: 0x9C/255, blue: 0xB3/255, alpha: 1)
            indicator.center = self.view.center
            indicator.startAnimating()
            
            let backdrop = UIView(frame: self.view.bounds)
            backdrop.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            backdrop.tag = 9999
            backdrop.addSubview(indicator)
            
            self.view.addSubview(backdrop)
            self.view.isUserInteractionEnabled = false
            
            self.loadingIndicator = indicator
        }
    }
    
    private func hideLoadingIndicator() {
        DispatchQueue.main.async {
            self.view.viewWithTag(9999)?.removeFromSuperview()
            self.loadingIndicator?.stopAnimating()
            self.loadingIndicator?.removeFromSuperview()
            self.loadingIndicator = nil
            self.view.isUserInteractionEnabled = true
        }
    }
    
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}

// MARK: - UITextFieldDelegate
extension OTPViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        // Only allow numbers and max 1 character
        if updatedText.count > 1 {
            return false
        }
        
        if !string.isEmpty && !CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string)) {
            return false
        }
        
        // Handle backspace - move to previous field
        if string.isEmpty && currentText.isEmpty {
            if let index = otpTextFields.firstIndex(of: textField), index > 0 {
                otpTextFields[index - 1].becomeFirstResponder()
            }
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Highlight the active field with nice animation
        if let containerView = textField.superview {
            UIView.animate(withDuration: 0.2) {
                containerView.layer.borderColor = UIColor(red: 0x77/255, green: 0x9C/255, blue: 0xB3/255, alpha: 1).cgColor
                containerView.layer.borderWidth = 2
            }
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Reset border when field loses focus
        if let containerView = textField.superview {
            UIView.animate(withDuration: 0.2) {
                containerView.layer.borderColor = UIColor(red: 0xD1/255, green: 0xD5/255, blue: 0xDB/255, alpha: 1).cgColor
                containerView.layer.borderWidth = 1.5
            }
        }
    }
}
