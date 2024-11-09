//
//  TextFieldAlert.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/25/23.
//

import UIKit

//
// Standard alert view with a text field
//
class TextFieldAlert: UIAlertController {

    var autocapitalizationType: UITextAutocapitalizationType? {
        get {
            if let textField = self.textFields?.first {
                return textField.autocapitalizationType
            } else {
                return nil
            }
        }
        set {
            if let newValue, let textField = self.textFields?.first {
                textField.autocapitalizationType = newValue
            }
        }
    }

    var text: String? {
        get {
            if let textField = self.textFields?.first {
                return textField.text
            } else {
                return nil
            }
        }
        set {
            if let newValue, let textField = self.textFields?.first {
                textField.text = newValue
            }
        }
    }

    convenience init(
        title: String,
        message: String?,
        placeholder: String,
        confirmText: String,
        completed: @escaping (String) -> Void
    ) {
        self.init(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        self.configure(placeholder: placeholder, confirmText: confirmText, completed: completed)
    }

    private func configure(placeholder: String, confirmText: String, completed: @escaping (String) -> Void) {
        self.view.tintColor = StyleGuide.colors.primary
        let textFieldConfig = { (textField: UITextField) in
            textField.autocapitalizationType = .words
            textField.autocorrectionType = .yes
            textField.placeholder = placeholder
        }
        self.addTextField(configurationHandler: textFieldConfig)
        self.addActions(confirmText: confirmText, completed: completed)
    }

    private func addActions(confirmText: String, completed: @escaping (String) -> Void) {
        let confirmAction = UIAlertAction(title: confirmText, style: .default) { (_) in
            if let textField = self.textFields?.first, let text = textField.text {
                completed(text)
            }
        }
        self.addAction(confirmAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        self.addAction(cancelAction)
    }
}
