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
        self.addActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addActions() {
        let okAction = UIAlertAction(title: "Ok", style: .destructive)
        self.alertController.addAction(okAction)
    }
}
