//
//  RBButton.swift
//  RecipeBook
//
//  Created by Ian Brault on 11/17/23.
//

import UIKit

class RBButton: UIButton {

    enum Style {
        case primary
        case secondary
    }

    init(title: String, image: UIImage? = nil, style: Style = .primary) {
        super.init(frame: .zero)
        self.configure(title: title, image: image, style: style)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(title: String, image: UIImage? = nil, style: Style) {
        self.translatesAutoresizingMaskIntoConstraints = false

        self.configuration = .filled()
        switch style {
        case .primary:
            self.configuration?.baseBackgroundColor = .systemYellow
            self.configuration?.baseForegroundColor = .systemBackground
        case .secondary:
            self.configuration?.baseBackgroundColor = .secondarySystemBackground
            self.configuration?.baseForegroundColor = .systemYellow
        }
        self.configuration?.cornerStyle = .large
        self.configuration?.attributedTitle = AttributedString(
            title,
            attributes: AttributeContainer([
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18, weight: .semibold)
            ])
        )

        if let image {
            self.configuration?.image = image
            self.configuration?.imagePadding = 16
            self.configuration?.imagePlacement = .leading
        }
    }
}
