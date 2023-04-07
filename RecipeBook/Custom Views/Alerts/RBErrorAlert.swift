//
//  RBErrorAlert.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/25/23.
//

import UIKit

class RBErrorAlert {

    var alertController: UIAlertController!

    init(title: String, message: String?) {
        self.alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        self.addAction()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addAction() {
        let okAction = UIAlertAction(title: "Continue", style: .default)
        self.alertController.addAction(okAction)
    }
}
