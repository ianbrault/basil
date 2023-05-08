//
//  RBDeleteRecipeAlert.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/7/23.
//

import UIKit

class RBDeleteRecipeItemAlert: UIAlertController {

    convenience init(item: RecipeItem, deleteAction: @escaping () -> Void) {
        var title: String!
        switch item {
        case .recipe(_):
            title = "Are you sure you want to delete this recipe?"
        case .folder(_):
            title = "Are you sure you want to delete this folder and all of its recipes?"
        }
        self.init(title: title, message: nil, preferredStyle: .actionSheet)
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
}
