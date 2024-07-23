//
//  RBNoConnectionView.swift
//  RecipeBook
//
//  Created by Ian Brault on 2/19/24.
//

import UIKit

class RBNoConnectionView: UIView {

    let imageView = UIImageView()
    let titleLabel = RBTitleLabel(fontSize: 14)
    let bodyLabel = RBBodyLabel(fontSize: 14)

    let height: CGFloat = 72
    let imageSize: CGFloat = 32

    let horizontalPadding: CGFloat = 16
    let verticalPadding: CGFloat = 10
    let horizontalMargin: CGFloat = 22
    let verticalMargin: CGFloat = 40

    init(in view: UIView) {
        super.init(frame: .zero)
        self.configureImageView()
        self.configureLabels()
        self.configureView(view: view)
        self.createTapGesture()

        // dismiss after a time
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            self.dismissView()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureImageView() {
        self.addSubview(self.imageView)
        self.imageView.translatesAutoresizingMaskIntoConstraints = false

        let image = SFSymbols.warning?.withTintColor(.systemYellow, renderingMode: .alwaysOriginal)
        let targetSize = image?.getImageSize(size: self.imageSize) ?? .zero
        self.imageView.image = image?.imageWith(newSize: targetSize).withRenderingMode(.alwaysOriginal)

        NSLayoutConstraint.activate([
            self.imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: self.horizontalPadding),
            self.imageView.widthAnchor.constraint(equalToConstant: self.imageSize),
            self.imageView.heightAnchor.constraint(equalToConstant: targetSize.height),
        ])
    }

    private func configureLabels() {
        self.addSubview(self.titleLabel)
        self.addSubview(self.bodyLabel)

        self.titleLabel.text = "Failed to connect to the server"
        self.titleLabel.textColor = .darkYellow

        self.bodyLabel.text = "Changes will not be saved to the server until you are back online"
        self.bodyLabel.textColor = .darkYellow
        self.bodyLabel.numberOfLines = 3
        self.bodyLabel.lineBreakMode = .byWordWrapping

        NSLayoutConstraint.activate([
            self.titleLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: self.verticalPadding),
            self.titleLabel.leadingAnchor.constraint(equalTo: self.imageView.trailingAnchor, constant: 16),
            self.titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.titleLabel.heightAnchor.constraint(equalToConstant: 16),

            self.bodyLabel.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor),
            self.bodyLabel.leadingAnchor.constraint(equalTo: self.imageView.trailingAnchor, constant: 16),
            self.bodyLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -self.horizontalPadding),
            self.bodyLabel.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    private func configureView(view: UIView) {
        let width = view.frame.size.width - (self.horizontalMargin * 2)
        let startY = view.frame.size.height + self.height
        let endY = view.frame.size.height - self.height - self.verticalMargin
        self.frame = CGRect(x: self.horizontalMargin, y: startY, width: width, height: self.height)

        self.backgroundColor = .paleYellow
        self.layer.borderWidth = 1.5
        self.layer.borderColor = UIColor.systemYellow.cgColor
        self.layer.cornerRadius = 12
        self.addShadow()

        // animate the modal appearance
        UIView.animate(withDuration: 0.32) {
            self.frame = CGRect(x: self.horizontalMargin, y: endY, width: width, height: self.height)
        }
    }

    private func createTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.dismissView))
        self.addGestureRecognizer(tap)
    }

    @objc func dismissView() {
        UIView.animate(withDuration: 0.32) {
            self.frame = CGRect(x: self.frame.minX, y: self.frame.minY + 32, width: self.frame.width, height: self.frame.height)
            self.layer.opacity = 0
        } completion: { (_) in
            self.removeFromSuperview()
        }
    }
}
