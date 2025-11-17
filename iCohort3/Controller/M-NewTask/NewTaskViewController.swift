//
//  NewTaskViewController.swift
//  iCohort3
//
//  Created by user@51 on 17/11/25.
//

import UIKit

class NewTaskViewController: UIViewController {
    @IBOutlet weak var headerView: UIView!
    
    @IBOutlet weak var assignButton: UIButton!
    @IBOutlet weak var assignView: UIView!
    @IBOutlet weak var confirmAssign: UIButton!
    @IBOutlet weak var descritionTextField: UITextField!
    @IBOutlet weak var descriptionView: UIView!
    @IBOutlet weak var attachmentButton: UIButton!
    @IBOutlet weak var attachmentView: UIView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var taskView: UIView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        taskView.layer.cornerRadius = 20
        descriptionView.layer.cornerRadius = 20
        assignView.layer.cornerRadius = 20
    }
    
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }

    @IBAction func doneButtonTapped(_ sender: Any) {
            return
        }
    

    
//    @IBAction func addTaskButtonTapped(_ sender: UIButton) {
//        let newTaskVC = NewTaskViewController(nibName: "NewTaskViewController", bundle: nil)
//        newTaskVC.modalPresentationStyle = .fullScreen
//        navigationController?.pushViewController(newTaskVC, animated: true)
//    }


//        @IBAction func addTaskButtonTapped(_ sender: UIButton) {
//            let newTaskVC = NewTaskViewController(nibName: "NewTaskViewController", bundle: nil)
//            newTaskVC.modalPresentationStyle = .fullScreen
//            present(newTaskVC, animated: true, completion: nil)
//        }
//    }


    

}
