//
//  UIViewController+Ext.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/25/23.
//

import UIKit

extension UIViewController {

    func notImplementedAlert() {
        let alert = RBErrorAlert(title: "Not implemented!", message: "This feature is not implemented. Try again later...")
        self.present(alert.alertController, animated: true)
    }
}
