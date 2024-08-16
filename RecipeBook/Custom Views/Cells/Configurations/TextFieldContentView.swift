//
//  TextFieldContentView.swift
//  RecipeBook
//
//  Created by Ian Brault on 8/13/24.
//

import UIKit

struct TextFieldContentConfiguration: UIContentConfiguration {

    var image: UIImage? = nil
    var tintColor: UIColor = .systemYellow

    var text: String = ""
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    var isSecureTextEntry: Bool = false

    var onChange: ((String?, UIView) -> Void)?

    var imageSize: CGFloat = 24
    var contentInset: CGFloat = 16
    var imageToTextPadding: CGFloat = 16

    func makeContentView() -> UIView & UIContentView {
        return TextFieldContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> TextFieldContentConfiguration {
        return self
    }
}

class TextFieldContentView: UIView, UIContentView {

    var configuration: UIContentConfiguration {
        didSet {
            self.configure()
        }
    }

    let imageView = UIImageView()
    let textField = UITextField()

    init(configuration: TextFieldContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        guard let configuration = self.configuration as? TextFieldContentConfiguration else { return }

        self.addSubview(self.imageView)
        self.addSubview(self.textField)

        self.imageView.image = configuration.image
        self.imageView.tintColor = configuration.tintColor
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.translatesAutoresizingMaskIntoConstraints = false

        self.textField.text = configuration.text
        self.textField.placeholder = configuration.placeholder
        self.textField.keyboardType = configuration.keyboardType
        self.textField.isSecureTextEntry = configuration.isSecureTextEntry
        self.textField.autocapitalizationType = .none
        self.textField.clearButtonMode = .whileEditing
        self.textField.translatesAutoresizingMaskIntoConstraints = false

        self.textField.addAction(UIAction { (action) in
            if let sender = action.sender as? UITextField {
                configuration.onChange?(sender.text, sender)
            }
        }, for: .editingChanged)

        self.imageView.heightAnchor.constraint(equalToConstant: configuration.imageSize).isActive = true
        self.imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        self.imageView.centerXAnchor.constraint(
            equalTo: self.leadingAnchor, constant: (configuration.imageSize / 2) + configuration.contentInset
        ).isActive = true

        self.textField.leadingAnchor.constraint(
            equalTo: self.imageView.centerXAnchor, constant: (configuration.imageSize / 2) + configuration.imageToTextPadding
        ).isActive = true
        self.textField.trailingAnchor.constraint(
            equalTo: self.trailingAnchor, constant: -configuration.contentInset
        ).isActive = true
        self.textField.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        self.textField.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
    }
}
