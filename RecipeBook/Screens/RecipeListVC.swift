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
        self.configureNavigationBarOnAppear()
        self.loadRecipes()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureViewController()
        self.configureTableView()
    }

    func configureNavigationBarOnAppear() {
        self.title = "Recipes"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }

    func configureNavigationBarOnDisappear() {
        // clear the title to avoid it overlapping the following view when pushed
        self.title = ""
        let backButton = UIBarButtonItem()
        backButton.title = "Recipes"
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
    }

    func configureViewController() {
        self.view.backgroundColor = .systemBackground

        // add an add button to add new recipes
        let addButton = UIBarButtonItem(systemItem: .add, menu: createAddButtonContextMenu())
        self.navigationItem.rightBarButtonItem = addButton
    }

    func configureTableView() {
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
        self.configureNavigationBarOnDisappear()

        let recipe = self.recipes[indexPath.row]
        let recipeVC = RecipeVC()
        recipeVC.recipe = recipe
        self.navigationController?.pushViewController(recipeVC, animated: true)
    }
}

extension RecipeListVC: RecipeFormVCDelegate {

    func savedRecipe(recipe: Recipe) {
        print("saved recipe")
        do {
            self.recipes.append(recipe)
            try PersistenceManager.saveRecipes(recipes: self.recipes)
            self.removeEmptyStateView(in: self.view)
            self.tableView.reloadData()
        } catch {
            self.presentErrorAlert(.failedToSaveRecipes)
        }
    }
}

extension RecipeListVC: RBTextFieldAlertDelegate {

    func didSubmitText(text: String) {
        self.notImplementedAlert()
    }
}
