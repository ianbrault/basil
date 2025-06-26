//
//  DeleteRecipeItemAlert.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/7/23.
//

import UIKit

//
// Alert when the user is deleting a recipe/folder
//
class DeleteRecipeItemAlert: UIAlertController {

    convenience init(item: RecipeItem, deleteAction: @escaping () -> Void) {
        self.init(title: "Delete \"\(item.text)\"", message: Self.message(item: item), preferredStyle: .actionSheet)
        self.view.tintColor = StyleGuide.colors.primary
        self.addActions(actionHandler: deleteAction)
    }

    func addActions(actionHandler: @escaping () -> Void) {
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (_) in
            actionHandler()
        }
        self.addAction(deleteAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        self.addAction(cancelAction)
    }

    static func message(item: RecipeItem) -> String {
        switch item {
        case .recipe(_):
            return "Are you sure you want to delete this recipe?"
        case .folder(_):
            return "Are you sure you want to delete this folder and all of its recipes?"
        }
    }
}
