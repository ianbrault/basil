//
//  RecipeListVC.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/22/23.
//

import UIKit

class RecipeListVC: UIViewController {

    let tableView = UITableView()
    var recipes: [Recipe] = []

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureNavigationBar()
        self.loadRecipes()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureViewController()
        self.configureTableView()
    }

    private func configureNavigationBar() {
        self.title = "Recipes"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.navigationBar.tintColor = .systemYellow

        let appearance = UINavigationBarAppearance()
        appearance.largeTitleTextAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 32, weight: .bold),
        ]
        self.navigationController?.navigationBar.standardAppearance = appearance
    }

    private func configureViewController() {
        self.view.backgroundColor = .systemBackground

        // add an add button to add new recipes
        let addButton = UIBarButtonItem(systemItem: .add, menu: createAddButtonContextMenu())
        self.navigationItem.rightBarButtonItem = addButton
    }

    private func configureTableView() {
        self.view.addSubview(self.tableView)

        self.tableView.frame = self.view.bounds
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.removeExcessCells()

        self.tableView.register(RecipeCell.self, forCellReuseIdentifier: RecipeCell.reuseID)
    }

    func loadRecipes() {
        PersistenceManager.fetchRecipes { [weak self] (result) in
            guard let self else { return }

            switch result {
            case .success(let recipes):
                // show the empty state view if there are no favorites
                if recipes.isEmpty {
                    self.showEmptyStateView(in: self.view)
                } else {
                    self.recipes = recipes
                    // reload table view data on the main thread
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        // ensure that the table view is brought to the front in case the empty state view is still there
                        self.view.bringSubviewToFront(self.tableView)
                    }
                }

            case .failure(let error):
                // update UI on the main thread
                DispatchQueue.main.async {
                    self.presentErrorAlert(error)
                }
            }
        }
    }

    func createAddButtonContextMenu() -> UIMenu {
        let menuItems = [
            UIAction(title: "Add new recipe", image: SFSymbols.addRecipe, handler: self.addNewRecipe),
            UIAction(title: "Import recipe", image: SFSymbols.importRecipe, handler: self.importRecipe),
        ]

        return UIMenu(title: "", image: nil, identifier: nil, options: [], children: menuItems)
    }

    func addNewRecipe(_ action: UIAction) {
        let destVC = RecipeFormVC()
        destVC.delegate = self

        let navController = UINavigationController(rootViewController: destVC)
        self.present(navController, animated: true)
    }

    func importRecipe(_ action: UIAction) {
        let alert = RBTextFieldAlert(title: "Import a recipe", message: nil, placeholder: "URL")
        alert.delegate = self
        self.present(alert.alertController, animated: true)
    }
}

extension RecipeListVC: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.recipes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecipeCell.reuseID) as! RecipeCell
        let recipe = self.recipes[indexPath.row]
        cell.set(recipe: recipe)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let recipe = self.recipes[indexPath.row]
        let recipeVC = RecipeVC()
        recipeVC.recipe = recipe
        self.navigationController?.pushViewController(recipeVC, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let contextItem = UIContextualAction(style: .destructive, title: "Delete") {  (action, view, actionPerformed) in
            let alert = RBDeleteRecipeAlert { [weak self] () in
                guard let self = self else { return }
                // save the initial recipe state in case PersistenceManager throws
                let previous_recipes = self.recipes

                self.recipes.remove(at: indexPath.row)
                PersistenceManager.saveRecipes(recipes: recipes) { [weak self] (error) in
                    guard let self else { return }
                    if let error {
                        // restore the original recipe state
                        self.recipes = previous_recipes
                        actionPerformed(false)
                        self.presentErrorAlert(error)
                    } else {
                        self.tableView.deleteRows(at: [indexPath], with: .automatic)
                        // if this was the last recipe, show the empty state view
                        if self.recipes.isEmpty {
                            self.showEmptyStateView(in: self.view)
                        }
                        actionPerformed(true)
                    }
                }
            }
            self.present(alert.alertController, animated: true)
        }
        return UISwipeActionsConfiguration(actions: [contextItem])
    }
}

extension RecipeListVC: RecipeFormVCDelegate {

    func savedRecipe(recipe: Recipe) {
        self.recipes.append(recipe)
        PersistenceManager.saveRecipes(recipes: recipes) { [weak self] (error) in
            guard let self else { return }
            // save the initial recipe state in case PersistenceManager throws
            let previous_recipes = self.recipes

            if let error {
                // restore the original recipe state
                self.recipes = previous_recipes
                self.presentErrorAlert(error)
            } else {
                self.removeEmptyStateView(in: self.view)
                self.tableView.reloadData()
            }
        }
    }
}

extension RecipeListVC: RBTextFieldAlertDelegate {

    func didSubmitText(text: String) {
        self.notImplementedAlert()
    }
}
