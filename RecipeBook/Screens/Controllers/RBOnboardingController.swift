//
//  RBOnboardingController.swift
//  RecipeBook
//
//  Created by Ian Brault on 8/9/24.
//

import UIKit

class RBOnboardingController: UINavigationController {

    private let rootVC = WelcomeVC()

    init() {
        super.init(rootViewController: self.rootVC)

        self.navigationBar.prefersLargeTitles = true
        self.navigationBar.tintColor = Style.colors.primary

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
