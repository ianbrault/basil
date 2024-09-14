//
//  RBAddGroceriesAlert.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/17/24.
//

import UIKit

//
// Alert to prompt to add ingredients from a recipe to the grocery list
//
class RBAddGroceriesAlert: UIAlertController {

    convenience init(recipe: Recipe) {
        let title = "Add the ingredients for \"\(recipe.title)\" to your grocery list?"
        self.init(title: title, message: nil, preferredStyle: .actionSheet)
        self.view.tintColor = StyleGuide.colors.primary
        self.addActions(recipe: recipe)
    }

    private func addActions(recipe: Recipe) {
        let deleteAction = UIAlertAction(title: "Add", style: .default) { (_) in
            State.manager.addToGroceryList(from: recipe)
        }
        self.addAction(deleteAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        self.addAction(cancelAction)
    }
}
