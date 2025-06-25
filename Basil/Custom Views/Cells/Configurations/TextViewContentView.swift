//
//  TextViewContentView.swift
//  RecipeBook
//
//  Created by Ian Brault on 9/7/24.
//

import UIKit

struct TextViewContentConfiguration: UIContentConfiguration {

    var image: UIImage? = nil
    var tintColor: UIColor = StyleGuide.colors.primary

    var text: String = ""
    var placeholder: String = ""
    var autocapitalizationType: UITextAutocapitalizationType = .none
    var font: UIFont = StyleGuide.fonts.body
    var textColor: UIColor = StyleGuide.colors.primaryText

    var contentInset: CGFloat = 16
    var imageSize: CGFloat = 24
    var imageToTextPadding: CGFloat = 16

    var onChange: ((String) -> Void)?
    var onBeginEditing: ((String) -> Void)?
    var onEndEditing: ((String) -> Void)?
    var onImageTap: (() -> Void)?

    func makeContentView() -> UIView & UIContentView {
        return TextViewContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> Self {
        return self
    }
}

class TextViewContentView: UIView, UIContentView {

    var configuration: UIContentConfiguration {
        didSet {
            self.configure()
        }
    }

    private let stackView = UIStackView()
    private let image = UIImageView()
    private let textView = UITextView()
    private let placeholder = UILabel()

    private let imageWidthAnchor: NSLayoutConstraint
    private let imageHeightAnchor: NSLayoutConstraint
    private let placeholderHeightAnchor: NSLayoutConstraint

    override var intrinsicContentSize: CGSize {
        CGSize(width: 0, height: StyleGuide.tableCellHeightInteractive)
    }

    init(configuration: TextViewContentConfiguration) {
        self.imageWidthAnchor = self.image.widthAnchor.constraint(equalToConstant: configuration.imageSize)
        self.imageHeightAnchor = self.image.heightAnchor.constraint(equalToConstant: configuration.imageSize)
        self.placeholderHeightAnchor = self.placeholder.heightAnchor.constraint(
            equalToConstant: configuration.font.pointSize * 1.1
        )
        self.configuration = configuration
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func attributedText(_ text: String, color: UIColor = StyleGuide.colors.primaryText) -> NSAttributedString {
        guard let configuration = self.configuration as? TextViewContentConfiguration else { return NSAttributedString() }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = configuration.font.pointSize * 0.10
        return NSAttributedString(
            string: text,
            attributes: [.font: configuration.font, .paragraphStyle: paragraphStyle, .foregroundColor: color]
        )
    }

    private func configure() {
        guard let configuration = self.configuration as? TextViewContentConfiguration else { return }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.imageTapped))
        tapGesture.delegate = self
        self.addGestureRecognizer(tapGesture)

        self.image.image = configuration.image
        self.image.tintColor = configuration.tintColor
        self.image.contentMode = .scaleAspectFit
        self.image.clipsToBounds = true
        self.image.isUserInteractionEnabled = true

        self.textView.attributedText = self.attributedText(configuration.text, color: configuration.textColor)
        self.textView.delegate = self
        self.textView.autocapitalizationType = configuration.autocapitalizationType
        self.textView.font = configuration.font
        self.textView.isScrollEnabled = false

        self.placeholder.text = configuration.placeholder
        self.placeholder.font = configuration.font
        self.placeholder.textColor = StyleGuide.colors.tertiaryText
        self.placeholder.isHidden = !configuration.text.isEmpty
        self.placeholder.translatesAutoresizingMaskIntoConstraints = false

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

        self.stackView.addArrangedSubview(self.textView)

        self.addPinnedSubview(self.stackView)

        self.addSubview(self.placeholder)
        self.placeholder.topAnchor.constraint(equalTo: self.textView.topAnchor, constant: self.textView.textContainerInset.top).isActive = true
        self.placeholder.leadingAnchor.constraint(equalTo: self.textView.leadingAnchor, constant: self.textView.textContainerInset.left + 4).isActive = true
        self.placeholder.widthAnchor.constraint(equalTo: self.textView.widthAnchor).isActive = true
        self.placeholderHeightAnchor.constant = configuration.font.pointSize * 1.3
        self.placeholderHeightAnchor.isActive = true
    }

    override func becomeFirstResponder() -> Bool {
        self.textView.becomeFirstResponder()
    }

    @objc func imageTapped() {
        guard let configuration = self.configuration as? TextViewContentConfiguration else { return }
        configuration.onImageTap?()
    }
}

extension TextViewContentView: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let configuration = self.configuration as? TextViewContentConfiguration else { return false }

        let taploc = touch.location(in: self)
        return taploc.x < configuration.contentInset + configuration.imageSize + configuration.imageToTextPadding
    }
}

extension TextViewContentView: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        guard let configuration = self.configuration as? TextViewContentConfiguration else { return }
        self.placeholder.isHidden = !textView.text.isEmpty
        configuration.onChange?(textView.text)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        guard let configuration = self.configuration as? TextViewContentConfiguration else { return }
        configuration.onBeginEditing?(textView.text)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        guard let configuration = self.configuration as? TextViewContentConfiguration else { return }
        self.placeholder.isHidden = !textView.text.isEmpty
        configuration.onEndEditing?(textView.text)
    }
}
