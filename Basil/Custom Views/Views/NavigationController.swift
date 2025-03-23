//
//  NavigationController.swift
//  Basil
//
//  Created by Ian Brault on 3/16/25.
//

import UIKit

class NavigationController: UINavigationController {

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)

        self.navigationBar.prefersLargeTitles = true
        self.navigationBar.tintColor = StyleGuide.colors.primary

        let appearance = UINavigationBarAppearance()
        appearance.largeTitleTextAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 32, weight: .bold),
        ]
        self.navigationBar.standardAppearance = appearance
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
