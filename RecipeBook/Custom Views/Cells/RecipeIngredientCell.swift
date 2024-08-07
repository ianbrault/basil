//
//  RecipeIngredientCell.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/8/23.
//

import UIKit

class RecipeIngredientCell: UITableViewCell {
    static let reuseID = "RecipeIngredientCell"

    let ingredientLabel = UITextView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(ingredient: Ingredient) {
        let string = "•\t\(ingredient.toString())"

        let paragraphStyle = NSMutableParagraphStyle()
        let bulletSize = NSAttributedString(
            string: "•",
            attributes: [.font: self.ingredientLabel.font!]).size()
        let itemStart = bulletSize.width + 8
        paragraphStyle.headIndent = itemStart
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: itemStart)]
        paragraphStyle.lineSpacing = 4
        paragraphStyle.paragraphSpacing = 10

        let attributedText = NSAttributedString(
            string: string,
            attributes: [.paragraphStyle: paragraphStyle, .font: self.ingredientLabel.font!])
        self.ingredientLabel.attributedText = attributedText
    }

    private func configure() {
        self.addSubview(self.ingredientLabel)

        self.ingredientLabel.translatesAutoresizingMaskIntoConstraints = false
        self.ingredientLabel.font = .systemFont(ofSize: 16)
        self.ingredientLabel.isScrollEnabled = false
        self.ingredientLabel.textContainer.lineFragmentPadding = 0
        self.ingredientLabel.textContainerInset = .zero

        NSLayoutConstraint.activate([
            self.ingredientLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 4),
            self.ingredientLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -4),
            self.ingredientLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 24),
            self.ingredientLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -24),
        ])
    }
}
