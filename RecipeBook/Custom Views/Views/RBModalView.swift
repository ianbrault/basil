//
//  RBModalView.swift
//  RecipeBook
//
//  Created by Ian Brault on 2/19/24.
//

import UIKit

class RBModalView: UIView {

    let imageView = UIImageView()
    let label = RBBodyLabel(fontSize: 16)

    let height: CGFloat = 60
    let imageSize: CGFloat = 28

    let innerPadding: CGFloat = 20
    let horizontalPadding: CGFloat = 32
    let verticalPadding: CGFloat = 45

    init(image: UIImage?, text: String, in view: UIView) {
        super.init(frame: .zero)
        self.configureImageView(image: image)
        self.configureLabel(text: text)
        self.configureView(view: view)
        self.createSwipeGestures()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func getImageSize(image: UIImage?) -> CGSize {
        if let image {
            let scaleFactor = self.imageSize / image.size.width
            let height = image.size.height * scaleFactor
            return CGSize(width: self.imageSize, height: height)
        } else {
            return .zero
        }
    }

    private func configureImageView(image: UIImage?) {
        self.addSubview(self.imageView)
        self.imageView.translatesAutoresizingMaskIntoConstraints = false

        let targetSize = self.getImageSize(image: image)
        self.imageView.image = image?.imageWith(newSize: targetSize).withRenderingMode(.alwaysOriginal)

        NSLayoutConstraint.activate([
            self.imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: self.innerPadding),
            self.imageView.widthAnchor.constraint(equalToConstant: self.imageSize),
            self.imageView.heightAnchor.constraint(equalToConstant: targetSize.height),
        ])
    }

    private func configureLabel(text: String) {
        self.addSubview(self.label)
        self.label.text = text
        self.label.textColor = .secondaryLabel

        NSLayoutConstraint.activate([
            self.label.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.label.leadingAnchor.constraint(equalTo: self.imageView.trailingAnchor, constant: 12),
            self.label.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.label.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    private func configureView(view: UIView) {
        let width = view.frame.size.width - (self.horizontalPadding * 2)
        let startY = view.frame.size.height + self.height
        let endY = view.frame.size.height - self.height - self.verticalPadding
        self.frame = CGRect(x: self.horizontalPadding, y: startY, width: width, height: self.height)

        self.backgroundColor = .secondarySystemBackground
        self.layer.cornerRadius = 10
        self.addShadow()

        // animate the modal appearance
        UIView.animate(withDuration: 0.32) {
            self.frame = CGRect(x: self.horizontalPadding, y: endY, width: width, height: self.height)
        }
    }

    private func createSwipeGestures() {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(self.viewSwiped))
        self.addGestureRecognizer(swipe)
    }

    @objc func viewSwiped(gesture: UIGestureRecognizer) {
        guard let superview = self.superview else { return }
        guard let swipeGesture = gesture as? UISwipeGestureRecognizer else { return }

        var x: CGFloat = self.horizontalPadding
        var y: CGFloat = superview.frame.height - self.height - self.verticalPadding
        switch swipeGesture.direction {
        case .down:
            y = superview.frame.height + self.height
        case .left:
            x = -self.frame.width
        case .right:
            x = superview.frame.width + self.frame.width
        case .up:
            return
        default:
            return
        }

        UIView.animate(withDuration: 0.32) {
            self.frame = CGRect(x: x, y: y, width: self.frame.width, height: self.frame.height)
        } completion: { (_) in
            self.removeFromSuperview()
        }
    }
}
