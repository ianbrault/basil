//
//  RecipeListVC.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/22/23.
//

import UIKit

class RecipeListVC: UIViewController {

    let tableView = UITableView()
    // let recipes: [Recipe] = []
    // FIXME: test data
    let recipes: [Recipe] = [
        Recipe(title: "Coconut Chicken Curry", ingredients: [], instructions: []),
        Recipe(title: "Baked Tofu with Peanut Sauce and Coconut-Lime Rice", ingredients: [], instructions: []),
        Recipe(title: "Roasted Brussels Sprouts", ingredients: [], instructions: []),
        Recipe(title: "Pear Torte", ingredients: [], instructions: []),
    ]

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureNavigationBarOnAppear()
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

        // add an add button to the naviation bar which will add new recipes
        // let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped))
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

    func createAddButtonContextMenu() -> UIMenu {
        let menuItems = [
            UIAction(title: "Add new recipe", image: SFSymbols.addRecipe, handler: self.addNewRecipe),
            UIAction(title: "Import recipe", image: SFSymbols.importRecipe, handler: self.importRecipe),
        ]

        return UIMenu(title: "", image: nil, identifier: nil, options: [], children: menuItems)
    }

    func addNewRecipe(_ action: UIAction) {
        print("add new recipe")
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

extension RecipeListVC: RBTextFieldAlertDelegate {

    func didSubmitText(text: String) {
        self.notImplementedAlert()
    }
}
