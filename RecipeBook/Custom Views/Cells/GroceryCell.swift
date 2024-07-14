//
//  GroceryCell.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/9/24.
//

import UIKit

class GroceryCell: UITableViewCell {
    static let reuseID = "GroceryCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = .systemBackground
        self.tintColor = .systemYellow
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(grocery: Grocery) {
        var content = self.defaultContentConfiguration()
        content.text = grocery.toString()

        if grocery.complete {
            content.image = SFSymbols.checkmarkCircleFill
            content.imageProperties.tintColor = .systemYellow
        } else {
            content.image = SFSymbols.circle
            content.imageProperties.tintColor = .secondaryLabel
        }

        self.contentConfiguration = content
    }
}
