//
//  BodyLabel.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/24/23.
//

import UIKit

class BodyLabel: UILabel {

    init(textAlignment: NSTextAlignment = .left) {
        super.init(frame: .zero)
        self.configure(textAlignment: textAlignment)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(textAlignment: NSTextAlignment) {
        self.translatesAutoresizingMaskIntoConstraints = false

        self.font = UIFont.preferredFont(forTextStyle: .body)
        self.textAlignment = textAlignment
        self.textColor = .label
        self.lineBreakMode = .byWordWrapping
    }
}
