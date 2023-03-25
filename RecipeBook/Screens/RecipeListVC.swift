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
        configureNavigationBarOnAppear()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewController()
        configureTableView()
    }

    func configureNavigationBarOnAppear() {
        title = "Recipes"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    func configureNavigationBarOnDisappear() {
        // clear the title to avoid it overlapping the following view when pushed
        title = ""
        let backButton = UIBarButtonItem()
        backButton.title = "Recipes"
        navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
    }

    func configureViewController() {
        view.backgroundColor = .systemBackground

        // add an add button to the naviation bar which will add new recipes
        // let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped))
        let addButton = UIBarButtonItem(systemItem: .add, menu: createAddButtonContextMenu())
        navigationItem.rightBarButtonItem = addButton
    }

    func configureTableView() {
        view.addSubview(tableView)

        tableView.frame = view.bounds
        tableView.delegate = self
        tableView.dataSource = self
        tableView.removeExcessCells()

        tableView.register(RecipeCell.self, forCellReuseIdentifier: RecipeCell.reuseID)
    }

    func createAddButtonContextMenu() -> UIMenu {
        let menuItems = [
            UIAction(title: "Add new recipe", image: SFSymbols.addRecipe, handler: addNewRecipe),
            UIAction(title: "Import recipe", image: SFSymbols.importRecipe, handler: importRecipe),
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
        return recipes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecipeCell.reuseID) as! RecipeCell
        let recipe = recipes[indexPath.row]
        cell.set(recipe: recipe)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        configureNavigationBarOnDisappear()

        let recipe = recipes[indexPath.row]
        let recipeVC = RecipeVC()
        recipeVC.recipe = recipe
        navigationController?.pushViewController(recipeVC, animated: true)
    }
}

extension RecipeListVC: RBTextFieldAlertDelegate {

    func didSubmitText(text: String) {
        self.notImplementedAlert()
    }
}
