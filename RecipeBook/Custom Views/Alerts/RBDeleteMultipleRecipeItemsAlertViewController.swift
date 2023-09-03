//
//  RBDeleteMultipleRecipeItemsAlertViewController.swift
//  RecipeBook
//
//  Created by Ian Brault on 9/2/23.
//

import UIKit

class RBDeleteMultipleRecipeItemsAlertViewController: UIAlertController {

    convenience init(count: Int, deleteAction: @escaping () -> Void) {
        let title = "Are you sure you want to delete these \(count) items?"
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
