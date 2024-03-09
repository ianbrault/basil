//
//  RBProcessingView.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/3/24.
//

import UIKit

class RBProcessingView: UIView {

    let activityIndicator = UIActivityIndicatorView()
    let label = RBBodyLabel(fontSize: 14)

    let height: CGFloat = 40
    let spinnerSize: CGFloat = 24

    let horizontalPadding: CGFloat = 16
    let verticalPadding: CGFloat = 10
    let horizontalMargin: CGFloat = 36
    let verticalMargin: CGFloat = 40

    init(in view: UIView) {
        super.init(frame: .zero)
        self.configureSpinner()
        self.configureLabels()
        self.configureView(view: view)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureSpinner() {
        self.addSubview(self.activityIndicator)
        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.activityIndicator.startAnimating()

        NSLayoutConstraint.activate([
            self.activityIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.activityIndicator.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: self.horizontalPadding),
            self.activityIndicator.heightAnchor.constraint(equalToConstant: self.spinnerSize),
        ])
    }

    private func configureLabels() {
        self.addSubview(self.label)

        self.label.text = "Uploading your recipes to the server"
        self.label.textColor = .secondaryLabel

        NSLayoutConstraint.activate([
            self.label.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.label.leadingAnchor.constraint(equalTo: self.activityIndicator.trailingAnchor, constant: 16),
            self.label.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -self.horizontalPadding),
            self.label.heightAnchor.constraint(equalToConstant: 18),
        ])
    }

    private func configureView(view: UIView) {
        let width = view.frame.size.width - (self.horizontalMargin * 2)
        let startY = view.frame.size.height + self.height
        let endY = view.frame.size.height - self.height - self.verticalMargin
        self.frame = CGRect(x: self.horizontalMargin, y: startY, width: width, height: self.height)

        self.backgroundColor = .secondarySystemBackground
        self.layer.cornerRadius = 12
        self.addShadow()

        // animate the modal appearance
        UIView.animate(withDuration: 0.32) {
            self.frame = CGRect(x: self.horizontalMargin, y: endY, width: width, height: self.height)
        }
    }

    func dismissView() {
        UIView.animate(withDuration: 0.32) {
            self.frame = CGRect(x: self.frame.minX, y: self.frame.minY + 32, width: self.frame.width, height: self.frame.height)
            self.layer.opacity = 0
        } completion: { (_) in
            self.removeFromSuperview()
        }
    }
}
