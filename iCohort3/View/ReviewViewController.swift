//
//  ReviewViewController.swift
//  iCohort3
//
//  Created by user@0 on 17/11/25.
//

import UIKit

class ReviewViewController: UIViewController, UITextViewDelegate  {
    
    
    // MARK: - Top
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!      // "Review"
    
    // MARK: - Cards (containers)
    @IBOutlet weak var titleCardView: UIView!        // Colour Palette + Due Date
    @IBOutlet weak var attachmentCardView: UIView!   // Attachment
    @IBOutlet weak var descriptionCardView: UIView!  // Add remark
    @IBOutlet weak var assignedToCardView: UIView!   // Assigned To
    @IBOutlet weak var statusCardView: UIView!       // Status
    
    // MARK: - Inside cards
    @IBOutlet weak var dueDateValueLabel: UILabel!       // right side of "Due Date"
    @IBOutlet weak var remarkTextView: UITextView!       // description / remark
    @IBOutlet weak var assigneeNameLabel: UILabel!       // "Shreya Singh"
    @IBOutlet weak var statusValueLabel: UILabel!        // "In Review"
    
    // MARK: - Bottom buttons
    @IBOutlet weak var rejectButton: UIButton!
    @IBOutlet weak var completeButton: UIButton!
    
    // Placeholder text for remark
    private let remarkPlaceholder = "Add remark"
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(
            red: 0xEF/255.0,
            green: 0xEF/255.0,
            blue: 0xF5/255.0,
            alpha: 1.0
        )
        
        setupCards()
        setupDueDateLabel()
        setupRemarkTextView()
        setupAssignedTo()
        setupStatus()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        styleTopBackButton()
        styleBottomButtons()
    }
    
    // MARK: - Setup helpers
    
    private func setupCards() {
        let cards = [
            titleCardView,
            attachmentCardView,
            descriptionCardView,
            assignedToCardView,
            statusCardView
        ]
        
        for card in cards.compactMap({ $0 }) {
            card.layer.cornerRadius = 16
            card.layer.masksToBounds = true
            card.backgroundColor = .white
        }
    }
    
    private func styleTopBackButton() {
        backButton.layer.cornerRadius = backButton.bounds.height / 2
        backButton.layer.masksToBounds = true
        backButton.backgroundColor = .white
    }
    
    private func styleBottomButtons() {
        [rejectButton, completeButton].forEach { button in
            guard let button = button else { return }
            button.layer.cornerRadius = button.bounds.height / 2
            button.layer.masksToBounds = true
            button.backgroundColor = .white
        }
        
        rejectButton.setTitleColor(.systemRed, for: .normal)
        completeButton.setTitleColor(.systemGreen, for: .normal)
    }
    
    // MARK: - Specific UI elements
    
    private func setupDueDateLabel() {
        // Set any date you want here
        dueDateValueLabel.text = "25 Sep 2025"
        dueDateValueLabel.textColor = .systemGray
    }
    
    private func setupRemarkTextView() {
        remarkTextView.delegate = self
        remarkTextView.text = remarkPlaceholder
        remarkTextView.textColor = .systemGray3
        remarkTextView.backgroundColor = .clear
    }
    
    private func setupAssignedTo() {
        assigneeNameLabel.text = "Shreya Singh"
        assigneeNameLabel.textColor = .systemGray
    }
    
    private func setupStatus() {
        statusValueLabel.text = "In Review"
        statusValueLabel.textColor = UIColor.systemYellow
    }
    
    // MARK: - Actions
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func rejectButtonTapped(_ sender: UIButton) {
        print("Reject tapped")
        // add your logic here
    }
    
    @IBAction func completeButtonTapped(_ sender: UIButton) {
        print("Complete tapped")
        // add your logic here
    }
    
    // MARK: - UITextViewDelegate (placeholder behaviour)
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView == remarkTextView,
           textView.text == remarkPlaceholder {
            textView.text = ""
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == remarkTextView {
            let trimmed = textView.text
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                textView.text = remarkPlaceholder
                textView.textColor = .systemGray3
            }
        }
    }
}


