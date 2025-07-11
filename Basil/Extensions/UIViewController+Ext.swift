//
//  UIViewController+Ext.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/25/23.
//

import UIKit

extension UIViewController {

    @objc func dismissSelf() {
        self.dismiss(animated: true)
    }

    func addNotificationObserver(name: NSNotification.Name?, selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
    }

    func createBarButton(image: UIImage?, action: Selector?) -> UIBarButtonItem {
        return UIBarButtonItem(title: nil, image: image, target: self, action: action)
    }

    func createBarButton(title: String?, style: UIBarButtonItem.Style, action: Selector?) -> UIBarButtonItem {
        return UIBarButtonItem(title: title, style: style, target: self, action: action)
    }

    func createBarButton(systemItem: UIBarButtonItem.SystemItem, action: Selector?) -> UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: systemItem, target: self, action: action)
    }

    func createBarButton(image: UIImage?, menu: UIMenu?) -> UIBarButtonItem {
        return UIBarButtonItem(image: image, menu: menu)
    }

    func presentErrorAlert(_ error: BasilError) {
        DispatchQueue.main.async {
            let alert = ErrorAlert(error: error)
            self.present(alert, animated: true)
        }
    }

    func notImplementedAlert() {
        self.presentErrorAlert(.notImplemented)
    }

    func showLoadingView() {
        let view = LoadingView(frame: self.view.bounds)
        self.view.addSubview(view)
        UIView.animate(withDuration: 0.5) {
            view.alpha = 0.8
        }
        view.startAnimating()
    }

    func dismissLoadingView() {
        for subview in self.view.subviews {
            if let view = subview as? LoadingView {
                DispatchQueue.main.async {
                    view.removeFromSuperview()
                }
            }
        }
    }
}
