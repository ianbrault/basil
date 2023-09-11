//
//  RecipeCell.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/24/23.
//

import UIKit

class RecipeCell: UITableViewCell {
    static let reuseID = "RecipeCell"

    private func configure() {
        self.tintColor = .systemYellow

        let selectedBackground = UIView()
        selectedBackground.backgroundColor = .systemGray6
        self.selectedBackgroundView = selectedBackground
    }

    private func contentConfiguration() -> UIListContentConfiguration {
        var content = self.defaultContentConfiguration()
        content.textProperties.lineBreakMode = .byTruncatingTail
        content.textProperties.numberOfLines = 1
        return content
    }

    private func setRecipe(recipe: Recipe) {
        self.accessoryType = .none

        var content = self.contentConfiguration()
        content.text = recipe.title
        self.contentConfiguration = content
    }

    private func setFolder(folder: RecipeFolder) {
        self.accessoryType = .disclosureIndicator

        var content = self.contentConfiguration()
        content.attributedText = folder.attributedText()
        self.contentConfiguration = content
    }

    func set(item: RecipeItem) {
        self.configure()

        switch item {
        case .recipe(let recipe):
            self.setRecipe(recipe: recipe)
        case .folder(let folder):
            self.setFolder(folder: folder)
        }
    }
}
