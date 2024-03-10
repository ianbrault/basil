//
//  RBEmptyStateView.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/6/23.
//

import UIKit

class RBEmptyStateView: UIView {

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

    let logoImageView = UIImageView()
    let messageLabel = RBTitleLabel(fontSize: 16, weight: .regular, textAlignment: .center)

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
        self.addSubview(self.logoImageView)

        let symbol = UIImage(
            systemName: style.systemName,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: self.imageSize, weight: .light))
        let image = symbol?.withTintColor(.tertiaryLabel, renderingMode: .alwaysOriginal)

        self.logoImageView.image = image
        self.logoImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            self.logoImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.logoImageView.bottomAnchor.constraint(equalTo: self.centerYAnchor),
            self.logoImageView.widthAnchor.constraint(equalToConstant: self.imageSize),
            self.logoImageView.heightAnchor.constraint(equalToConstant: self.imageSize),
        ])
    }

    private func configureMessageLabel(style: Style) {
        self.addSubview(self.messageLabel)

        self.messageLabel.attributedText = self.getMessageAttributedText(style: style)
        self.messageLabel.numberOfLines = 3
        self.messageLabel.textColor = .secondaryLabel

        NSLayoutConstraint.activate([
            self.messageLabel.topAnchor.constraint(equalTo: self.logoImageView.bottomAnchor, constant: self.spacing),
            self.messageLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: self.padding),
            self.messageLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -self.padding),
        ])
    }
}
