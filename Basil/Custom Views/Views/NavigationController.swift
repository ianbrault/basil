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
        self.navigationBar.standardAppearance = StyleGuide.navigationBarAppearance
        self.navigationBar.tintColor = StyleGuide.colors.primary
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
