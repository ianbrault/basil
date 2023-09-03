//
//  RBWarningAlert.swift
//  RecipeBook
//
//  Created by Ian Brault on 9/3/23.
//

import UIKit

class RBWarningAlert: UIAlertController {

    convenience init(message: String, actionStyle: UIAlertAction.Style, action: @escaping () -> Void) {
        self.init(title: "Warning!", message: message, preferredStyle: .actionSheet)
        self.addActions(actionStyle: actionStyle, actionHandler: action)
    }

    func addActions(actionStyle: UIAlertAction.Style, actionHandler: @escaping () -> Void) {
        let deleteAction = UIAlertAction(title: "Continue", style: actionStyle) { (_) in
            actionHandler()
        }
        self.addAction(deleteAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        self.addAction(cancelAction)
    }
}
