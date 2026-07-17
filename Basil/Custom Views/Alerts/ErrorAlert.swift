//
//  ErrorAlert.swift
//  RecipeBook
//
//  Created by Ian Brault on 5/7/23.
//

import UIKit
import os

class ErrorAlert: UIAlertController {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: ErrorAlert.self)
    )

    convenience init(error: Error) {
        Self.logger.error("\(error)")
        if let basilError = error as? BasilError {
            self.init(title: "Something went wrong", message: basilError.message, preferredStyle: .alert)
        } else {
            self.init(title: "Something went wrong", message: error.localizedDescription, preferredStyle: .alert)
        }
        self.view.tintColor = StyleGuide.colors.primary
        self.addActions()
    }

    private func addActions() {
        let action = UIAlertAction(title: "Continue", style: .default)
        self.addAction(action)
    }
}
