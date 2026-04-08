//
//  SplashViewController.swift
//  iCohort3
//

import UIKit

class SplashViewController: UIViewController {

    var onFinish: (() -> Void)?

    private let bgGradient = CAGradientLayer()
    private let logoView = AnimatedAuthLogoView()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup Background Gradient
        bgGradient.type = .radial
        bgGradient.colors = [
            UIColor(red: 0.17, green: 0.27, blue: 0.35, alpha: 1.0).cgColor, // #2C4659
            UIColor(red: 0.06, green: 0.10, blue: 0.14, alpha: 1.0).cgColor  // #0F1A24
        ]
        bgGradient.startPoint = CGPoint(x: 0.5, y: 0.5)
        bgGradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        view.layer.addSublayer(bgGradient)

        // Setup the animated logo view
        logoView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoView)

        // The exact size of the login screen logo is 160x160 or 180x180.
        // We configure it to 140x140 here so it isn't fully zoomed in.
        NSLayoutConstraint.activate([
            logoView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoView.widthAnchor.constraint(equalToConstant: 140),
            logoView.heightAnchor.constraint(equalToConstant: 140)
        ])

        // Add pop-in and fade-in entrance animation to the AnimatedAuthLogoView
        logoView.alpha = 0
        logoView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        
        UIView.animate(
            withDuration: 1.0,
            delay: 0.1,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut,
            animations: {
                self.logoView.alpha = 1
                self.logoView.transform = .identity
            }, completion: nil
        )

        // Schedule completion handoff (reduced time from 2.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.onFinish?()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bgGradient.frame = view.bounds
    }
}
