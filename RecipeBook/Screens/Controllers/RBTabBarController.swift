//
//  RBTabBarController.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/22/23.
//

import UIKit

class RBTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        UITabBar.appearance().tintColor = .systemYellow
        self.viewControllers = [
            self.createRecipeListVC(),
            self.createGroceryListVC(),
        ]
    }

    private func createNavigationController(rootViewController: UIViewController) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: rootViewController)

        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.navigationBar.tintColor = .systemYellow

        let appearance = UINavigationBarAppearance()
        appearance.largeTitleTextAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 32, weight: .bold),
        ]
        navigationController.navigationBar.standardAppearance = appearance

        return navigationController
    }

    private func createRecipeListVC() -> UINavigationController {
        let recipeListVC = RecipeListVC(folderId: State.manager.root!)
        recipeListVC.tabBarItem = UITabBarItem(title: "Recipes", image: SFSymbols.recipeBook, tag: 0)

        return self.createNavigationController(rootViewController: recipeListVC)
    }

    private func createGroceryListVC() -> UINavigationController {
        let groceryListVC = GroceryListVC()
        groceryListVC.tabBarItem = UITabBarItem(title: "Groceries", image: SFSymbols.groceries, tag: 1)

        return self.createNavigationController(rootViewController: groceryListVC)
    }
}
