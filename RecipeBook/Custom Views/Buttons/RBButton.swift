//
//  RBButton.swift
//  RecipeBook
//
//  Created by Ian Brault on 11/17/23.
//

import UIKit

class RBButton: UIButton {

    enum Style {
        case filled
        case bordered
    }

    init(title: String, image: UIImage? = nil, style: Style = .filled) {
        super.init(frame: .zero)
        self.configure(title: title, image: image, style: style)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        self.layer.cornerRadius = 10
        self.layer.masksToBounds = false

        self.addShadow()
    }

    private func configure(title: String, image: UIImage? = nil, style: Style) {
        self.translatesAutoresizingMaskIntoConstraints = false

        switch style {
        case .filled:
            self.configuration = .filled()
            self.configuration?.cornerStyle = .medium
            self.configuration?.baseBackgroundColor = .systemYellow
            self.configuration?.baseForegroundColor = .systemBackground

        case .bordered:
            self.configuration = .bordered()
            self.configuration?.cornerStyle = .medium
            self.configuration?.baseBackgroundColor = .systemBackground
            self.configuration?.baseForegroundColor = .systemYellow
            self.layer.borderColor = UIColor.systemYellow.cgColor
            self.layer.borderWidth = 2
        }

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
