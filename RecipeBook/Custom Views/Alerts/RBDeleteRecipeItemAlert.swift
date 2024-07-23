//
//  RBDeleteRecipeAlert.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/7/23.
//

import UIKit

//
// Alert when the user is deleting a recipe/folder
//
class RBDeleteRecipeItemAlert: RBDeleteAlert {

    convenience init(item: RecipeItem, deleteAction: @escaping () -> Void) {
        var title: String!
        switch item {
        case .recipe(_):
            title = "Are you sure you want to delete this recipe?"
        case .folder(_):
            title = "Are you sure you want to delete this folder and all of its recipes?"
        }
        self.init(title: title, deleteAction: deleteAction)
    }
}
