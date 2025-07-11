//
//  LoadingView.swift
//  Basil
//
//  Created by Ian Brault on 7/9/25.
//

import UIKit

class LoadingView: UIView {

    private let activityIndicator = UIActivityIndicatorView(style: .large)

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        self.addSubview(self.activityIndicator)
        self.alpha = 0
        self.backgroundColor = StyleGuide.colors.background

        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.activityIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        self.activityIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
    }

    func startAnimating() {
        self.activityIndicator.startAnimating()
    }
}
