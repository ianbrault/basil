//
//  TextViewContentView.swift
//  RecipeBook
//
//  Created by Ian Brault on 9/7/24.
//

import UIKit

struct TextViewContentConfiguration: UIContentConfiguration {

    var text: String = ""
    var placeholder: String = ""
    var autocapitalizationType: UITextAutocapitalizationType = .none

    var onChange: ((String) -> Void)?

    var insets: UIEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 0, right: 12)

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

    private let textView = UITextView()
    private let placeholderLabel = BodyLabel()
    private var onChange: ((String) -> Void)?

    static func attributedText(_ text: String, color: UIColor = .label) -> NSAttributedString {
        let font = UIFont.preferredFont(forTextStyle: .body)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = font.pointSize * 0.10
        return NSAttributedString(
            string: text,
            attributes: [.font: font, .paragraphStyle: paragraphStyle, .foregroundColor: color]
        )
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: 0, height: StyleGuide.tableCellHeight)
    }

    init(configuration: TextViewContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        guard let configuration = self.configuration as? TextViewContentConfiguration else { return }
        self.onChange = configuration.onChange

        let placeholderInsets = UIEdgeInsets(
            top: 0, left: configuration.insets.left + 5,
            bottom: 0, right: configuration.insets.right + 5,
        )
        self.addPinnedSubview(self.textView, insets: configuration.insets)
        self.addPinnedSubview(self.placeholderLabel, insets: placeholderInsets)

        self.textView.attributedText = TextViewContentView.attributedText(configuration.text)
        self.textView.delegate = self
        self.textView.autocapitalizationType = configuration.autocapitalizationType
        self.textView.font = UIFont.preferredFont(forTextStyle: .body)
        self.textView.isScrollEnabled = false

        self.placeholderLabel.text = configuration.placeholder
        self.placeholderLabel.textColor = StyleGuide.colors.secondaryText
        self.placeholderLabel.isHidden = !configuration.text.isEmpty
    }

    override func becomeFirstResponder() -> Bool {
        self.textView.becomeFirstResponder()
    }
}

extension TextViewContentView: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        self.placeholderLabel.isHidden = !textView.text.isEmpty
        self.onChange?(textView.text ?? "")
    }
}
