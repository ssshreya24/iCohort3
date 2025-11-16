//
//  AddTaskViewController.swift
//  iCohort3
//
//  Created by user@51 on 16/11/25.
//

import UIKit

class AddTaskViewController: UIViewController {

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    
    @IBOutlet weak var categoryView: UIView!
    
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var categoryName: UITextField!
    
    @IBOutlet weak var colorChangeView: UIView!
    @IBOutlet weak var colorOptionsView: UIView!
    
    @IBOutlet weak var redColorView: UIButton!
    @IBOutlet weak var orangeColorView: UIButton!
    @IBOutlet weak var yellowColor: UIButton!
    @IBOutlet weak var greenColor: UIButton!
    @IBOutlet weak var blueColor: UIButton!
    @IBOutlet weak var tealColor: UIButton!
    @IBOutlet weak var addAttachmentView: UIView!
    
    @IBOutlet weak var addAttachmentButton: UIButton!
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    
    private var selectedColor: UIColor = .systemYellow
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        setupColorButtons()
        setupTextFieldListener()
        
        titleView.layer.cornerRadius = 20
        categoryView.layer.cornerRadius = 20
        colorChangeView.layer.cornerRadius = 20
        addAttachmentView.layer.cornerRadius = 20
    }
    
    
    
    private func setupTextFieldListener() {
        categoryName.addTarget(self, action: #selector(categoryNameChanged(_:)), for: .editingChanged)
    }

    @objc private func categoryNameChanged(_ sender: UITextField) {
        categoryLabel.text = sender.text?.isEmpty == false ? sender.text : "Label"
    }
    
    private func setupColorButtons() {
        let buttons = [redColorView, orangeColorView, yellowColor, greenColor, blueColor, tealColor]

        for btn in buttons {
            btn?.layer.cornerRadius = (btn?.frame.height ?? 40) / 2
            btn?.layer.masksToBounds = true
            btn?.addTarget(self, action: #selector(colorTapped(_:)), for: .touchUpInside)
        }
    }
    
    @objc private func colorTapped(_ sender: UIButton) {

        switch sender {
        case redColorView:
            selectedColor = UIColor.systemRed
        case orangeColorView:
            selectedColor = UIColor.orange
        case yellowColor:
            selectedColor = UIColor.systemYellow
        case greenColor:
            selectedColor = UIColor.systemGreen
        case blueColor:
            selectedColor = UIColor.systemBlue
        case tealColor:
            selectedColor = UIColor.systemTeal
        default:
            break
        }

        applySelectedColor()
        updateColorSelectionIndicators(selected: sender)
    }
    
    private func applySelectedColor() {
        colorChangeView.backgroundColor = selectedColor
        categoryLabel.backgroundColor = selectedColor

        // Feel like Apple Reminders: white text on dark colors
        categoryLabel.textColor = selectedColor.isLight ? .black : .white
    }
    
    private func updateColorSelectionIndicators(selected: UIButton) {
        let allButtons = [redColorView, orangeColorView, yellowColor, greenColor, blueColor, tealColor]

        for btn in allButtons {
            btn?.setImage(nil, for: .normal)
        }

    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }


    
    @IBAction func closeButtonTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }

    @IBAction func doneButtonTapped(_ sender: Any) {

        // Optional basic validation
        if let title = titleTextField.text, title.isEmpty {
            showAlert(message: "Please enter a title.")
            return
        }

        // TODO: save your task here

        self.dismiss(animated: true)
    }

}


extension UIColor {
    var isLight: Bool {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green:&green, blue:&blue, alpha:&alpha)
        let brightness = ((red * 299) + (green * 587) + (blue * 114)) / 1000
        return brightness > 0.75
    }
}
