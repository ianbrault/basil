//
//  RBAddGroceriesAlert.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/17/24.
//

import UIKit

class RBAddGroceriesAlert: UIAlertController {

    convenience init(recipe: Recipe) {
        let title = "Add the ingredients for \"\(recipe.title)\" to your grocery list?"
        self.init(title: title, message: nil, preferredStyle: .actionSheet)
        self.addActions(recipe: recipe)
    }

    func addActions(recipe: Recipe) {
        let deleteAction = UIAlertAction(title: "Add", style: .default) { (_) in
            State.manager.addIngredientsToGroceryList(from: recipe)
        }
        self.addAction(deleteAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        self.addAction(cancelAction)
    }
}
