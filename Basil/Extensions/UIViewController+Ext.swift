//
//  UIViewController+Ext.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/25/23.
//

import UIKit

fileprivate var containerView: UIView!

extension UIViewController {

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

    func presentErrorAlert(_ error: RBError) {
        let alert = ErrorAlert(error: error)
        self.present(alert, animated: true)
    }

    func notImplementedAlert() {
        self.presentErrorAlert(.notImplemented)
    }

    func showEmptyStateView(_ style: EmptyStateView.Style, in view: UIView) {
        self.removeEmptyStateView(in: view)

        let emptyStateView = EmptyStateView(style, frame: view.bounds)
        view.addSubview(emptyStateView)
    }

    func removeEmptyStateView(in view: UIView) {
        view.subviews.forEach { (subview) in
            if subview is EmptyStateView {
                subview.removeFromSuperview()
            }
        }
    }

    func showLoadingView() {
        containerView = UIView(frame: view.bounds)
        self.view.addSubview(containerView)

        containerView.backgroundColor = .systemBackground
        containerView.alpha = 0

        UIView.animate(withDuration: 0.5) {
            containerView.alpha = 0.8
        }

        let activityIndicator = UIActivityIndicatorView(style: .large)
        containerView.addSubview(activityIndicator)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            activityIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
        ])

        activityIndicator.startAnimating()
    }

    func dismissLoadingView() {
        DispatchQueue.main.async {
            containerView.removeFromSuperview()
            containerView = nil
        }
    }
}
