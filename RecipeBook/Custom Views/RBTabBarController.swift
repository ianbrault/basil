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
        viewControllers = [createRecipeListVC(), createGroceryListVC()]
    }

    func createRecipeListVC() -> UINavigationController {
        let recipeListVC = RecipeListVC()
        recipeListVC.tabBarItem = UITabBarItem(title: "Recipes", image: SFSymbols.recipes, tag: 0)

        return UINavigationController(rootViewController: recipeListVC)
    }

    func createGroceryListVC() -> UINavigationController {
        let groceryListVC = GroceryListVC()
        groceryListVC.tabBarItem = UITabBarItem(title: "Groceries", image: SFSymbols.groceries, tag: 1)

        return UINavigationController(rootViewController: groceryListVC)
    }
}
