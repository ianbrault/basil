//
//  TextFieldContentView.swift
//  RecipeBook
//
//  Created by Ian Brault on 8/13/24.
//

import UIKit

struct TextFieldContentConfiguration: UIContentConfiguration {

    var image: UIImage? = nil
    var tintColor: UIColor = StyleGuide.colors.primary

    var text: String = ""
    var placeholder: String = ""
    var contentType: UITextContentType? = nil
    var keyboardType: UIKeyboardType = .default
    var isSecureTextEntry: Bool = false
    var autocapitalizationType: UITextAutocapitalizationType = .none

    var contentInset: CGFloat = 16
    var imageSize: CGFloat = 24
    var imageToTextPadding: CGFloat = 16

    var onChange: ((String) -> Void)?
    var onEndEditing: ((String) -> Void)?
    var onImageTap: (() -> Void)?

    func makeContentView() -> UIView & UIContentView {
        return TextFieldContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> Self {
        return self
    }
}

class TextFieldContentView: UIView, UIContentView {

    var configuration: UIContentConfiguration {
        didSet {
            self.configure()
        }
    }

    private let stackView = UIStackView()
    private let image = UIImageView()
    private let textField = UITextField()

    private let imageWidthAnchor: NSLayoutConstraint
    private let imageHeightAnchor: NSLayoutConstraint

    override var intrinsicContentSize: CGSize {
        CGSize(width: 0, height: StyleGuide.tableCellHeightInteractive)
    }

    init(configuration: TextFieldContentConfiguration) {
        self.imageWidthAnchor = self.image.widthAnchor.constraint(equalToConstant: configuration.imageSize)
        self.imageHeightAnchor = self.image.heightAnchor.constraint(equalToConstant: configuration.imageSize)
        self.configuration = configuration
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        guard let configuration = self.configuration as? TextFieldContentConfiguration else { return }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.imageTapped))
        tapGesture.delegate = self
        self.addGestureRecognizer(tapGesture)

        self.image.image = configuration.image
        self.image.tintColor = configuration.tintColor
        self.image.contentMode = .scaleAspectFit
        self.image.clipsToBounds = true
        self.image.isUserInteractionEnabled = true

        self.textField.text = configuration.text
        self.textField.placeholder = configuration.placeholder
        self.textField.textContentType = configuration.contentType
        self.textField.keyboardType = configuration.keyboardType
        self.textField.isSecureTextEntry = configuration.isSecureTextEntry
        self.textField.autocapitalizationType = configuration.autocapitalizationType
        self.textField.clearButtonMode = .whileEditing
        self.textField.addTarget(self, action: #selector(self.textChanged), for: .editingChanged)
        self.textField.addTarget(self, action: #selector(self.editingEnded), for: .editingDidEnd)

        self.stackView.axis = .horizontal
        self.stackView.alignment = .center
        self.stackView.spacing = configuration.imageToTextPadding
        self.stackView.isLayoutMarginsRelativeArrangement = true
        self.stackView.layoutMargins = UIEdgeInsets(top: 0, left: configuration.contentInset, bottom: 0, right: configuration.contentInset)
        self.stackView.removeAllArrangedSubviews()

        if let _ = configuration.image {
            self.stackView.addArrangedSubview(self.image)
            self.imageWidthAnchor.constant = configuration.imageSize
            self.imageHeightAnchor.constant = configuration.imageSize
            self.imageWidthAnchor.isActive = true
            self.imageHeightAnchor.isActive = true
        }

        self.stackView.addArrangedSubview(self.textField)

        self.addPinnedSubview(self.stackView)
    }

    override func becomeFirstResponder() -> Bool {
        self.textField.becomeFirstResponder()
    }

    @objc func textChanged(_ sender: UITextField) {
        guard let configuration = self.configuration as? TextFieldContentConfiguration else { return }
        configuration.onChange?(self.textField.text ?? "")
    }

    @objc func editingEnded(_ sender: UITextField) {
        guard let configuration = self.configuration as? TextFieldContentConfiguration else { return }
        configuration.onEndEditing?(self.textField.text ?? "")
    }

    @objc func imageTapped() {
        guard let configuration = self.configuration as? TextFieldContentConfiguration else { return }
        configuration.onImageTap?()
    }
}

extension TextFieldContentView: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let configuration = self.configuration as? TextFieldContentConfiguration else { return false }

        let taploc = touch.location(in: self)
        return taploc.x < configuration.contentInset + configuration.imageSize + configuration.imageToTextPadding
    }
}
