//
//  RBTitleLabel.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/24/23.
//

import UIKit

class RBTitleLabel: UILabel {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience init(fontSize: CGFloat, weight: UIFont.Weight = .bold, textAlignment: NSTextAlignment = .left) {
        self.init(frame: .zero)
        self.font = UIFont.systemFont(ofSize: fontSize, weight: weight)
        self.textAlignment = textAlignment
    }

    private func configure() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.textColor = .label
        self.lineBreakMode = .byWordWrapping
    }
}
