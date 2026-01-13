//
//  AdminSignUpViewController.swift
//  iCohort3
//
//  Created by user@51 on 12/01/26.
//

import UIKit

class AdminSignUpViewController: UIViewController {
    
    @IBOutlet weak var uniNameView: UIView!
    @IBOutlet weak var uniTextField: UITextField!
    @IBOutlet weak var mailView: UIView!
    @IBOutlet weak var mailTextField: UITextField!
    @IBOutlet weak var domainView: UIView!
    @IBOutlet weak var domainTextField: UITextField!
    @IBOutlet weak var passView: UIView!
    @IBOutlet weak var passTextField: UITextField!
    @IBOutlet weak var confirmPassView: UIView!
    @IBOutlet weak var confirmPassTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    // MARK: - UI Setup
    func setupUI() {
        let radius: CGFloat = 20
        
        // Apply corner radius to all views
        let views = [uniNameView, mailView, domainView, passView, confirmPassView]
        
        for view in views {
            view?.layer.cornerRadius = radius
            view?.clipsToBounds = true
        }
        
        // Apply corner radius to text fields
        let textFields = [uniTextField, mailTextField, domainTextField, passTextField, confirmPassTextField]
        
        for textField in textFields {
            textField?.layer.cornerRadius = radius
            textField?.clipsToBounds = true
        }
    }

    @IBAction func registerButton(_ sender: Any) {
        
    }
    
    @IBAction func backButton(_ sender: Any) {
        // Navigate back to AdminLoginViewController
        if let navigationController = navigationController {
            navigationController.popViewController(animated: true)
        } else {
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

}
