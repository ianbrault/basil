//
//  TabBarController.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/22/23.
//

import UIKit

class TabBarController: UITabBarController {

    private enum Index: Int {
        case GroceryList = 0
        case RecipeList = 1
        case Settings = 2
    }

    var cookingView: UINavigationController? = nil
    private var tag: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        UITabBar.appearance().tintColor = StyleGuide.colors.primary
        self.viewControllers = [
            self.createGroceryListVC(),
            self.createRecipeListVC(),
            self.createSettingsVC(),
        ]
        self.selectedIndex = Index.RecipeList.rawValue
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.checkForFirstLaunch()
    }

    private func createGroceryListVC() -> UINavigationController {
        let groceryListVC = GroceryListVC()
        groceryListVC.tabBarItem = UITabBarItem(title: "Groceries", image: SFSymbols.groceries, tag: self.tag)
        self.tag += 1
        return NavigationController(rootViewController: groceryListVC)
    }

    private func createRecipeListVC() -> UINavigationController {
        let recipeListVC = RecipeListVC(folderId: State.manager.root!)
        recipeListVC.tabBarItem = UITabBarItem(title: "Recipes", image: SFSymbols.recipeBook, tag: self.tag)
        self.tag += 1
        return NavigationController(rootViewController: recipeListVC)
    }

    private func createSettingsVC() -> UINavigationController {
        let settingsVC = SettingsVC()
        settingsVC.tabBarItem = UITabBarItem(title: "Settings", image: SFSymbols.settings, tag: self.tag)
        self.tag += 1
        return NavigationController(rootViewController: settingsVC)
    }

    private func checkForFirstLaunch() {
        if !PersistenceManager.shared.hasLaunched {
            let alert = UIAlertController(
                title: "Welcome to Basil!",
                message: "Go to the \"Settings\" tab to login or register a new account.",
                preferredStyle: .alert
            )
            alert.view.tintColor = StyleGuide.colors.primary
            alert.addAction(UIAlertAction(title: "Continue", style: .default))
            self.present(alert, animated: true)

            PersistenceManager.shared.hasLaunched = true
        }
    }

    func refreshRecipeLists() {
        let recipeListNavController = self.viewControllers?[Index.RecipeList.rawValue] as! NavigationController
        for vc in recipeListNavController.viewControllers {
            if let recipeListVC = vc as? RecipeListVC {
                recipeListVC.refresh()
            }
        }
    }

    func addRecipeToCookingView(recipe: Recipe) {
        var present = false
        if self.cookingView == nil {
            let viewController = CookingVC()
            viewController.cookingDelegate = self
            self.cookingView = NavigationController(rootViewController: viewController)
            present = true
        }

        guard let controller = self.cookingView, let view = controller.topViewController as? CookingVC else {
            return
        }
        view.addRecipe(recipe: recipe)
        if let sheetController = view.sheetPresentationController {
            sheetController.animateChanges {
                sheetController.selectedDetentIdentifier = .large
            }
        }
        if present {
            self.present(controller, animated: true)
        }
    }
}

extension TabBarController: CookingVC.Delegate {

    func doneCooking() {
        self.cookingView = nil
    }
}
