//
//  RBIconTextField.swift
//  RecipeBook
//
//  Created by Ian Brault on 11/28/23.
//

import UIKit

class RBIconTextField: UIView {

    class TextField: UITextField {
        let textPadding = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        var border = CALayer()
        let borderSize: CGFloat = 1

        init(placeholder: String) {
            super.init(frame: .zero)

            self.autocapitalizationType = .none
            self.placeholder = placeholder
            self.textColor = .label
            self.tintColor = .label
            self.translatesAutoresizingMaskIntoConstraints = false
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func textRect(forBounds bounds: CGRect) -> CGRect {
            let rect = super.textRect(forBounds: bounds)
            return rect.inset(by: self.textPadding)
        }

        override func editingRect(forBounds bounds: CGRect) -> CGRect {
            let rect = super.editingRect(forBounds: bounds)
            return rect.inset(by: self.textPadding)
        }

        func addBorder(color: UIColor, animated: Bool) {
            let width = self.frame.size.width
            let height = self.frame.size.height

            self.border.frame = CGRect(x: 0, y: height - self.borderSize, width: width, height: self.borderSize)
            self.border.backgroundColor = color.cgColor
            self.layer.addSublayer(self.border)

            if animated {
                let animation = CABasicAnimation(keyPath: "bounds")
                animation.duration = 0.1
                animation.fromValue = NSValue(cgRect: CGRect(x: 0, y: height - self.borderSize, width: 0, height: self.borderSize))
                animation.toValue = NSValue(cgRect: CGRect(x: 0, y: height - self.borderSize, width: width, height: self.borderSize))
                self.border.add(animation, forKey: "anim")
            }
        }

        func removeBorder() {
            self.border.removeFromSuperlayer()
        }
    }

    let imageView = UIImageView()
    let textField: TextField!

    let imageSize: CGFloat = 24
    let textFieldHeight: CGFloat = 42
    let spacing: CGFloat = 8

    var text: String? {
        self.textField.text
    }

    init(placeholder: String, image: UIImage?) {
        self.textField = TextField(placeholder: placeholder)
        super.init(frame: .zero)
        self.configure(image: image)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(image: UIImage?) {
        self.translatesAutoresizingMaskIntoConstraints = false

        self.configureImageView(image: image)
        self.configureTextField()
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
        self.imageView.image = image?.imageWith(newSize: targetSize).withRenderingMode(.alwaysTemplate)
        self.imageView.tintColor = .tertiaryLabel

        NSLayoutConstraint.activate([
            self.imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.imageView.widthAnchor.constraint(equalToConstant: self.imageSize),
            self.imageView.heightAnchor.constraint(equalToConstant: targetSize.height),
        ])
    }

    private func configureTextField() {
        self.addSubview(self.textField)

        self.textField.delegate = self

        NSLayoutConstraint.activate([
            self.textField.leadingAnchor.constraint(equalTo: self.imageView.trailingAnchor, constant: self.spacing),
            self.textField.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.textField.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.textField.heightAnchor.constraint(equalToConstant: self.textFieldHeight),
        ])
    }

    func setTint(color: UIColor, animated: Bool) {
        UIView.animate(withDuration: animated ? 0.1 : 0) {
            self.imageView.tintColor = color
        }
        self.textField.addBorder(color: color, animated: animated)
    }

    func removeTint(animated: Bool) {
        UIView.animate(withDuration: animated ? 0.1 : 0) {
            self.imageView.tintColor = .tertiaryLabel
        }
        self.textField.removeBorder()
    }
}

extension RBIconTextField: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.setTint(color: .systemYellow, animated: true)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        self.removeTint(animated: true)
    }
}
