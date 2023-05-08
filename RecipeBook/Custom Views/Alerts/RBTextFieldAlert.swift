//
//  RBTextFieldAlert.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/25/23.
//

import UIKit

// TODO: refactor alert classes
class RBTextFieldAlert {

    var alertController: UIAlertController!
    var buttonText: String!

    init(title: String, message: String?, placeholder: String, buttonText: String, completed: @escaping (String) -> Void) {
        self.alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert)
        let textFieldConfig = { (textField: UITextField) in
            textField.autocapitalizationType = .sentences
            textField.autocorrectionType = .yes
            textField.placeholder = placeholder
        }
        self.alertController.addTextField(configurationHandler: textFieldConfig)
        self.buttonText = buttonText
        self.addActions(completed: completed)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addActions(completed: @escaping (String) -> Void) {
        let confirmAction = UIAlertAction(title: self.buttonText, style: .default) { (_) in
            if let textField = self.alertController.textFields?.first, let text = textField.text {
                completed(text)
            }
        }
        self.alertController.addAction(confirmAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        self.alertController.addAction(cancelAction)
    }
}
