//
//  ErrorAlert.swift
//  RecipeBook
//
//  Created by Ian Brault on 5/7/23.
//

import UIKit

class ErrorAlert: UIAlertController {

    convenience init(error: Error) {
        self.init(title: "Something went wrong", message: String(describing: error), preferredStyle: .alert)
        self.view.tintColor = StyleGuide.colors.primary
        self.addActions()
    }

    private func addActions() {
        let action = UIAlertAction(title: "Continue", style: .default)
        self.addAction(action)
    }
}
