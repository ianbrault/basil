//
//  RBErrorAlertController.swift
//  RecipeBook
//
//  Created by Ian Brault on 5/7/23.
//

import UIKit

class RBErrorAlertController: UIAlertController {

    convenience init(error: RBError) {
        self.init(title: error.title, message: error.message, preferredStyle: .alert)
        self.addActions()
    }

    private func addActions() {
        let action = UIAlertAction(title: "Continue", style: .default)
        self.addAction(action)
    }
}
