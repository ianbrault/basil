//
//  TabBarController.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/22/23.
//

import UIKit

class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        UITabBar.appearance().tintColor = StyleGuide.colors.primary
        self.viewControllers = [
            self.createRecipeListVC(),
            self.createGroceryListVC(),
        ]
        self.checkForFirstLaunch()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !State.manager.serverPoked {
            self.establishServerCommunication()
        }
    }

    private func createNavigationController(rootViewController: UIViewController) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: rootViewController)

        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.navigationBar.tintColor = StyleGuide.colors.primary

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

    private func checkForFirstLaunch() {
        if !PersistenceManager.shared.hasLaunched {
            let alert = UIAlertController(
                title: "Welcome to Basil!",
                message: "Tap the profile icon in the top right to login or register a new account.",
                preferredStyle: .alert
            )
            alert.view.tintColor = StyleGuide.colors.primary
            alert.addAction(UIAlertAction(title: "Continue", style: .default))
            self.present(alert, animated: true)

            PersistenceManager.shared.hasLaunched = true
        }
    }

    private func showProcessingView() {
        DispatchQueue.main.async {
            // show the view while the local data is pushed to the server
            let vc = ProcessingView()
            self.present(vc, animated: true)
        }
    }

    private func hideProcessingView() {
        DispatchQueue.main.async {
            self.dismiss(animated: true)
        }
    }

    private func establishServerCommunication() {
        // only poke the server if the user is logged in
        guard !State.manager.userId.isEmpty else { return }

        State.manager.serverPoked = true
        API.pokeServer { (error) in
            if let _ = error {
                DispatchQueue.main.async {
                    UIApplication.shared.windowRootViewController?.presentErrorAlert(.noConnection)
                }
            } else {
                State.manager.serverCommunicationEstablished = true
                if PersistenceManager.shared.needsToUpdateServer {
                    self.showProcessingView()
                    API.updateUser { (error) in
                        self.hideProcessingView()
                        if let error {
                            DispatchQueue.main.async {
                                UIApplication.shared.windowRootViewController?.presentErrorAlert(error)
                            }
                        } else {
                            PersistenceManager.shared.needsToUpdateServer = false
                        }
                    }
                }
            }
        }
    }
}
