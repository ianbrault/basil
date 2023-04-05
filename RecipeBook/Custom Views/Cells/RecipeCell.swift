//
//  RecipeCell.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/24/23.
//

import UIKit

class RecipeCell: UITableViewCell {
    static let reuseID = "RecipeCell"

    let recipeTitleLabel = RBBodyLabel(fontSize: 16)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(recipe: Recipe) {
        self.recipeTitleLabel.text = recipe.title
    }

    private func configure() {
        self.addSubview(self.recipeTitleLabel)

        self.accessoryType = .disclosureIndicator

        self.recipeTitleLabel.lineBreakMode = .byTruncatingTail

        NSLayoutConstraint.activate([
            self.recipeTitleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.recipeTitleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 24),
            self.recipeTitleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -45),
            self.recipeTitleLabel.heightAnchor.constraint(equalToConstant: 24),
        ])
    }
}
