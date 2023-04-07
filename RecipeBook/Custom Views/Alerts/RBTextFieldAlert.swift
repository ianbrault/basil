//
//  RBTextFieldAlert.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/25/23.
//

import UIKit

protocol RBTextFieldAlertDelegate: AnyObject {
    func didSubmitText(text: String)
}

class RBTextFieldAlert {

    var alertController: UIAlertController!
    weak var delegate: RBTextFieldAlertDelegate!

    init(title: String, message: String?, placeholder: String) {
        self.alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert)
        let textFieldConfig = { (textField: UITextField) in
            textField.placeholder = placeholder
        }
        self.alertController.addTextField(configurationHandler: textFieldConfig)
        self.addActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addActions() {
        let confirmAction = UIAlertAction(title: "Import", style: .default) { (_) in
            if let textField = self.alertController.textFields?.first, let text = textField.text {
                self.delegate.didSubmitText(text: text)
            }
        }
        self.alertController.addAction(confirmAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        self.alertController.addAction(cancelAction)
    }
}
