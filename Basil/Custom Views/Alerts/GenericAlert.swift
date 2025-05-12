//
//  GenericAlert.swift
//  Basil
//
//  Created by Ian Brault on 5/11/25.
//

import UIKit

//
// Generic alert for presenting information
//
class GenericAlert: UIAlertController {

    convenience init(title: String, message: String? = nil) {
        self.init(title: title, message: message, preferredStyle: .alert)
        self.view.tintColor = StyleGuide.colors.primary

        let continueAction = UIAlertAction(title: "Continue", style: .default) {_ in }
        self.addAction(continueAction)
    }
}
