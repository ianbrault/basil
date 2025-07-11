//
//  WarningAlert.swift
//  Basil
//
//  Created by Ian Brault on 3/9/25.
//

import UIKit

//
// Generic alert for warning messages
//
class WarningAlert: UIAlertController {

    convenience init(title: String = "Warning", message: String? = nil, actionHandler: @escaping () -> Void) {
        self.init(title: title, message: message, preferredStyle: .alert)
        self.view.tintColor = StyleGuide.colors.primary
        self.addActions(actionHandler: actionHandler)
    }

    func addActions(actionHandler: @escaping () -> Void) {
        let continueAction = UIAlertAction(title: "Continue", style: .default) { (_) in
            actionHandler()
        }
        self.addAction(continueAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        self.addAction(cancelAction)
    }
}
