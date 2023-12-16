//
//  RBPlainButton.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/25/23.
//

import UIKit

class RBPlainButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience init(title: String, image: UIImage? = nil, buttonSize: UIButton.Configuration.Size = .medium) {
        self.init(frame: .zero)
        self.set(title: title, image: image, buttonSize: buttonSize)
    }

    private func configure() {
        self.translatesAutoresizingMaskIntoConstraints = false

        self.configuration = .plain()
    }

    final func set(title: String, image: UIImage?, buttonSize: UIButton.Configuration.Size) {
        self.configuration?.title = title
        self.configuration?.buttonSize = buttonSize
        self.configuration?.baseForegroundColor = .systemYellow

        if let image {
            self.configuration?.image = image.withTintColor(.systemYellow)
            self.configuration?.imagePadding = 6
            self.configuration?.imagePlacement = .leading
        }
    }
}
