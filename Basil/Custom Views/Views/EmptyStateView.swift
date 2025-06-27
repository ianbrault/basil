//
//  EmptyStateView.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/6/23.
//

import UIKit

class EmptyStateView: UIView {

    enum Style {
        case recipes
        case groceries

        var image: UIImage? {
            switch self {
            case .recipes:
                return SFSymbols.recipeBook
            case .groceries:
                return SFSymbols.groceries
            }
        }
    }

    private let stackView = UIStackView()
    private let imageView = UIImageView()
    private let label = UILabel()

    private let padding: CGFloat = 60
    private let spacing: CGFloat = 20
    private let imageSize: CGFloat = 72
    private let lineSpacing: CGFloat = 4

    init(_ style: Style, frame: CGRect = .zero) {
        super.init(frame: frame)
        self.configure(style: style)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(style: Style) {
        self.imageView.image = style.image
        self.imageView.tintColor = StyleGuide.colors.tertiaryText
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.widthAnchor.constraint(equalToConstant: self.imageSize).isActive = true
        self.imageView.heightAnchor.constraint(equalToConstant: self.imageSize).isActive = true

        self.label.attributedText = self.getMessageAttributedText(style: style)
        self.label.font = StyleGuide.fonts.body
        self.label.numberOfLines = 0
        self.label.textAlignment = .center
        self.label.textColor = StyleGuide.colors.secondaryText

        self.stackView.axis = .vertical
        self.stackView.alignment = .center
        self.stackView.spacing = self.spacing
        self.stackView.isLayoutMarginsRelativeArrangement = true
        self.stackView.layoutMargins = UIEdgeInsets(top: 0, left: self.padding, bottom: 0, right: self.padding)
        self.stackView.translatesAutoresizingMaskIntoConstraints = false

        self.stackView.addArrangedSubview(self.imageView)
        self.stackView.addArrangedSubview(self.label)

        self.addSubview(self.stackView)
        self.stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        self.stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        self.stackView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    }

    private func getMessageAttributedText(style: Style) -> NSAttributedString {
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = SFSymbols.add?.withTintColor(.secondaryLabel)

        var item: String
        switch style {
        case .recipes:
            item = "a recipe"
        case .groceries:
            item = "groceries"
        }

        let message = NSMutableAttributedString(string: "Add \(item) using the ")
        message.append(NSAttributedString(attachment: imageAttachment))
        message.append(NSAttributedString(string: " button in the top-right"))

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = self.lineSpacing

        let string = NSMutableAttributedString(attributedString: message)
        string.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, string.length))

        return string
    }
}
