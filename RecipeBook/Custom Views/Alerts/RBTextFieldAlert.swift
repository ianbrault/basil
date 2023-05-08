//
//  RBTextFieldAlert.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/25/23.
//

import UIKit

class RBTextFieldAlert: UIAlertController {

    var buttonText: String!

    convenience init(title: String, message: String?, placeholder: String, buttonText: String, completed: @escaping (String) -> Void) {
        self.init(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        let textFieldConfig = { (textField: UITextField) in
            textField.autocapitalizationType = .sentences
            textField.autocorrectionType = .yes
            textField.placeholder = placeholder
        }
        self.addTextField(configurationHandler: textFieldConfig)
        self.buttonText = buttonText
        self.addActions(completed: completed)
    }

    func addActions(completed: @escaping (String) -> Void) {
        let confirmAction = UIAlertAction(title: self.buttonText, style: .default) { (_) in
            if let textField = self.textFields?.first, let text = textField.text {
                completed(text)
            }
        }
        self.addAction(confirmAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        self.addAction(cancelAction)
    }
}
