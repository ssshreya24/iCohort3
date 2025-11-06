//
//  OTPViewController.swift
//  iCohort3
//
//  Created by user@56 on 06/11/25.
//

import UIKit

class OTPViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        if let otpView = Bundle.main.loadNibNamed("OTPView", owner: self, options: nil)?.first as? OTPView {
                  otpView.frame = view.bounds
                  otpView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                  view.addSubview(otpView)
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

}
