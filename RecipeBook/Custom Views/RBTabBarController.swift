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
        // load the state before creating the view controllers
        if let _ = State.manager.load() {
            // TODO: add better error handling
            print("ERROR: failed to load state")
        } else {
            self.viewControllers = [
                self.createRecipeListVC(),
                self.createGroceryListVC(),
            ]
        }
    }

    func createRecipeListVC() -> UINavigationController {
        let recipeListVC = RecipeListVC(folderId: State.manager.root!)
        recipeListVC.tabBarItem = UITabBarItem(title: "Recipes", image: SFSymbols.recipeBook, tag: 0)

        return UINavigationController(rootViewController: recipeListVC)
    }

    func createGroceryListVC() -> UINavigationController {
        let groceryListVC = GroceryListVC()
        groceryListVC.tabBarItem = UITabBarItem(title: "Groceries", image: SFSymbols.groceries, tag: 1)

        return UINavigationController(rootViewController: groceryListVC)
    }
}
