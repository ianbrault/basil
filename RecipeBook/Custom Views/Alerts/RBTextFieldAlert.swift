//
//  RBTextFieldAlert.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/25/23.
//

import UIKit

class RBTextFieldAlert: UIAlertController {

    convenience init(title: String, placeholder: String, confirmButtonText: String, completed: @escaping (String) -> Void) {
        self.init(title: title, message: nil, preferredStyle: UIAlertController.Style.alert)
        self.configure(placeholder: placeholder, text: nil, confirmButtonText: confirmButtonText, completed: completed)
    }

    convenience init(title: String, placeholder: String, text: String, confirmButtonText: String, completed: @escaping (String) -> Void) {
        self.init(title: title, message: nil, preferredStyle: UIAlertController.Style.alert)
        self.configure(placeholder: placeholder, text: text,  confirmButtonText: confirmButtonText, completed: completed)
    }

    private func configure(placeholder: String, text: String?, confirmButtonText: String, completed: @escaping (String) -> Void) {
        let textFieldConfig = { (textField: UITextField) in
            textField.autocapitalizationType = .words
            textField.autocorrectionType = .yes
            textField.placeholder = placeholder
            if let text {
                textField.text = text
            }
        }
        self.addTextField(configurationHandler: textFieldConfig)

        self.addActions(confirmButtonText: confirmButtonText,  completed: completed)
    }

    private func addActions(confirmButtonText: String, completed: @escaping (String) -> Void) {
        let confirmAction = UIAlertAction(title: confirmButtonText, style: .default) { (_) in
            if let textField = self.textFields?.first, let text = textField.text {
                completed(text)
            }
        }
        self.addAction(confirmAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        self.addAction(cancelAction)
    }
}
