//
//  UIViewController+Ext.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/25/23.
//

import UIKit

extension UIViewController {

    func presentErrorAlert(title: String, message: String? = nil) {
        let alert = RBErrorAlert(title: title, message: message)
        self.present(alert.alertController, animated: true)
    }

    func notImplementedAlert() {
        let alert = RBErrorAlert(title: "Not implemented!", message: "This feature is not implemented. Try again later...")
        self.present(alert.alertController, animated: true)
    }

    func addNotificationObserver(name: NSNotification.Name?, selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
    }
}
