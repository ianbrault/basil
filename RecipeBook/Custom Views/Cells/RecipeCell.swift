//
//  RecipeCell.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/24/23.
//

import UIKit

class RecipeCell: UITableViewCell {
    static let reuseID = "RecipeCell"

    private func setRecipe(recipe: Recipe) {
        self.accessoryType = .none

        var content = self.defaultContentConfiguration()
        content.text = recipe.title
        self.contentConfiguration = content
    }

    private func setFolder(folder: RecipeFolder) {
        self.accessoryType = .disclosureIndicator

        var content = self.defaultContentConfiguration()
        content.attributedText = folder.attributedText()
        self.contentConfiguration = content
    }

    func set(item: RecipeItem) {
        switch item {
        case .recipe(let recipe):
            self.setRecipe(recipe: recipe)
        case .folder(let folder):
            self.setFolder(folder: folder)
        }
    }
}
