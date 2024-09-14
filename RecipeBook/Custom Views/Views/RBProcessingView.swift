//
//  RBProcessingView.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/3/24.
//

import UIKit

class RBProcessingView: UIViewController {

    let activityIndicator = UIActivityIndicatorView()
    let label = RBBodyLabel()
    let insets = UIEdgeInsets(top: 32, left: 40, bottom: 32, right: 40)

    init() {
        super.init(nibName: nil, bundle: nil)
        self.isModalInPresentation = true
        self.modalPresentationStyle = .formSheet
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureViewController()
        self.configureSpinner()
        self.configureLabel()
    }

    private func configureViewController() {
        self.view.backgroundColor = StyleGuide.colors.background
        if let sheet = self.sheetPresentationController {
            sheet.detents = [
                .custom(identifier: UISheetPresentationController.Detent.Identifier("small")) { context in
                    0.15 * context.maximumDetentValue
                },
            ]
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.preferredCornerRadius = 32.0
        }
    }

    private func configureSpinner() {
        self.view.addSubview(self.activityIndicator)

        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.activityIndicator.startAnimating()

        NSLayoutConstraint.activate([
            self.activityIndicator.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: self.insets.left),
            self.activityIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: -10),
        ])
    }

    private func configureLabel() {
        self.view.addSubview(self.label)

        self.label.text = "Uploading offline recipes to the server, hang tight for a moment"
        self.label.numberOfLines = 2

        NSLayoutConstraint.activate([
            self.label.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: -10),
            self.label.leadingAnchor.constraint(equalTo: self.activityIndicator.trailingAnchor, constant: 20),
            self.label.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -self.insets.right),
            self.label.heightAnchor.constraint(equalToConstant: 64),
        ])
    }
}
