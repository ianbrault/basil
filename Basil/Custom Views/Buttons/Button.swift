//
//  Button.swift
//  RecipeBook
//
//  Created by Ian Brault on 11/17/23.
//

import UIKit

class Button: UIButton {

    enum ButtonStyle {
        case primary
        case secondary
        case plain
    }

    init(title: String, image: UIImage? = nil, style: ButtonStyle = .primary) {
        super.init(frame: .zero)
        self.configure(title: title, image: image, for: style)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(title: String, image: UIImage? = nil, for style: ButtonStyle) {
        self.translatesAutoresizingMaskIntoConstraints = false

        switch style {
        case .primary:
            self.configuration = .filled()
            self.configuration?.baseBackgroundColor = StyleGuide.colors.primary
            self.configuration?.baseForegroundColor = StyleGuide.colors.background
        case .secondary:
            self.configuration = .filled()
            self.configuration?.baseBackgroundColor = StyleGuide.colors.secondaryBackground
            self.configuration?.baseForegroundColor = StyleGuide.colors.primary
        case .plain:
            self.configuration = .plain()
            self.configuration?.baseBackgroundColor = .clear
            self.configuration?.baseForegroundColor = StyleGuide.colors.primary
        }
        self.configuration?.cornerStyle = .large
        self.configuration?.attributedTitle = AttributedString(
            title,
            attributes: AttributeContainer([NSAttributedString.Key.font: Self.font(for: style)])
        )

        if let image {
            self.configuration?.image = image
            self.configuration?.imagePadding = 16
            self.configuration?.imagePlacement = .leading
        }
    }

    private static func font(for style: ButtonStyle) -> UIFont {
        switch style {
        case .primary, .secondary:
            return StyleGuide.fonts.button
        case .plain:
            return StyleGuide.fonts.body
        }
    }
}
