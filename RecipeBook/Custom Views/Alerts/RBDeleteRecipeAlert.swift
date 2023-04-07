//
//  RBDeleteRecipeAlert.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/7/23.
//

import UIKit

class RBDeleteRecipeAlert {

    var alertController: UIAlertController!

    init(deleteAction: @escaping () -> Void) {
        self.alertController = UIAlertController(
            title: "Are you sure you want to delete this recipe?",
            message: nil,
            preferredStyle: .actionSheet)
        self.addActions(actionHandler: deleteAction)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addActions(actionHandler: @escaping () -> Void) {
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (_) in
            actionHandler()
        }
        self.alertController.addAction(deleteAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        self.alertController.addAction(cancelAction)
    }
}
