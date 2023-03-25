//
//  RecipeCell.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/24/23.
//

import UIKit

class RecipeCell: UITableViewCell {
    static let reuseID = "FavoriteCell"

    let recipeTitleLabel = RBBodyLabel(fontSize: 16)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(recipe: Recipe) {
        recipeTitleLabel.text = recipe.title
    }

    private func configure() {
        addSubview(recipeTitleLabel)

        accessoryType = .disclosureIndicator

        let padding: CGFloat = 24
        NSLayoutConstraint.activate([
            recipeTitleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            recipeTitleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: padding),
            recipeTitleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -padding),
            recipeTitleLabel.heightAnchor.constraint(equalToConstant: 22),
        ])
    }
}
