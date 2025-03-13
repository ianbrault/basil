//
//  UIApplication+Ext.swift
//  Basil
//
//  Created by Ian Brault on 11/26/24.
//

import UIKit

extension UIApplication {

    var windowRootViewController: UIViewController? {
        let window = self.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.last

        var rootViewController = window?.rootViewController
        if let navigationController = rootViewController as? UINavigationController {
            rootViewController = navigationController.viewControllers.first
        }
        if let tabBarController = rootViewController as? UITabBarController {
            rootViewController = tabBarController.selectedViewController
        }
        return rootViewController
    }
}
