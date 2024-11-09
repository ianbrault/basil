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

        var systemName: String {
            switch self {
            case .recipes:
                return "text.book.closed"
            case .groceries:
                return "cart"
            }
        }
    }

    let imageView = UIImageView()
    let label = BodyLabel(textAlignment: .center)

    let padding: CGFloat = 60
    let spacing: CGFloat = 20
    let imageSize: CGFloat = 72
    let lineSpacing: CGFloat = 4

    init(_ style: Style, frame: CGRect) {
        super.init(frame: frame)
        self.configure(style: style)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(style: Style) {
        self.configureLogoImageView(style: style)
        self.configureMessageLabel(style: style)
    }

    func getMessageAttributedText(style: Style) -> NSAttributedString {
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

    private func configureLogoImageView(style: Style) {
        self.addSubview(self.imageView)

        let symbol = UIImage(
            systemName: style.systemName,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: self.imageSize, weight: .light))
        let image = symbol?.withTintColor(.tertiaryLabel, renderingMode: .alwaysOriginal)

        self.imageView.image = image
        self.imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            self.imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.imageView.bottomAnchor.constraint(equalTo: self.centerYAnchor),
            self.imageView.widthAnchor.constraint(equalToConstant: self.imageSize),
            self.imageView.heightAnchor.constraint(equalToConstant: self.imageSize),
        ])
    }

    private func configureMessageLabel(style: Style) {
        self.addSubview(self.label)

        self.label.attributedText = self.getMessageAttributedText(style: style)
        self.label.numberOfLines = 3
        self.label.textColor = .secondaryLabel

        NSLayoutConstraint.activate([
            self.label.topAnchor.constraint(equalTo: self.imageView.bottomAnchor, constant: self.spacing),
            self.label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: self.padding),
            self.label.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -self.padding),
        ])
    }
}
