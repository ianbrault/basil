//
//  UIViewController+Ext.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/25/23.
//

import UIKit

extension UIViewController {

    func presentErrorAlert(_ error: RBError) {
        let alert = RBErrorAlertController(error: error)
        self.present(alert, animated: true)
    }

    func notImplementedAlert() {
        self.presentErrorAlert(.notImplemented)
    }

    func addNotificationObserver(name: NSNotification.Name?, selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
    }

    func showEmptyStateView(in view: UIView) {
        self.removeEmptyStateView(in: view)

        let emptyStateView = RBEmptyStateView()
        emptyStateView.frame = view.bounds
        view.addSubview(emptyStateView)
    }

    func removeEmptyStateView(in view: UIView) {
        view.subviews.forEach { (subview) in
            if subview is RBEmptyStateView {
                subview.removeFromSuperview()
            }
        }
    }
}
