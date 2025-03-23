//
//  DoneCookingAlert.swift
//  Basil
//
//  Created by Ian Brault on 3/16/25.
//

import UIKit

//
// Alert for closing the cooking view
//
class DoneCookingAlert: UIAlertController {

    convenience init(actionHandler: @escaping () -> Void) {
        self.init(title: "Done cooking?", message: nil, preferredStyle: .alert)
        self.view.tintColor = StyleGuide.colors.primary
        self.addActions(actionHandler: actionHandler)
    }

    func addActions(actionHandler: @escaping () -> Void) {
        let yesAction = UIAlertAction(title: "Yes", style: .default) { (_) in
            actionHandler()
        }
        self.addAction(yesAction)

        let noAction = UIAlertAction(title: "No", style: .cancel)
        self.addAction(noAction)
    }
}

