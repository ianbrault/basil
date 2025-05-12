//
//  ErrorAlert.swift
//  RecipeBook
//
//  Created by Ian Brault on 5/7/23.
//

import UIKit

class ErrorAlert: UIAlertController {

    convenience init(error: BasilError) {
        self.init(title: error.title, message: error.message, preferredStyle: .alert)
        self.view.tintColor = StyleGuide.colors.primary
        self.addActions()
    }

    private func addActions() {
        let action = UIAlertAction(title: "Continue", style: .default)
        self.addAction(action)
    }
}
