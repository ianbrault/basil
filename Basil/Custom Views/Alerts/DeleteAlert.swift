//
//  DeleteAlert.swift
//  RecipeBook
//
//  Created by Ian Brault on 7/14/24.
//

import UIKit

//
// Generic alert for deletion
//
class DeleteAlert: UIAlertController {

    convenience init(title: String, deleteAction: @escaping () -> Void) {
        self.init(title: title, message: nil, preferredStyle: .actionSheet)
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
}
