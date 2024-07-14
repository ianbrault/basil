//
//  RecipeVC.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/8/23.
//

import UIKit

protocol RecipeVCDelegate: AnyObject {
    func didDeleteRecipe(recipe: Recipe)
}

class RecipeVC: UIViewController {

    enum Section: Int {
        case title
        case ingredients
        case instructions

        var title: String? {
            switch self {
            case .title:
                return nil
            case .ingredients:
                return "Ingredients"
            case .instructions:
                return "Instructions"
            }
        }
    }

    let tableView = UITableView()

    var recipe: Recipe!
    weak var delegate: RecipeVCDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureViewController()
        self.configureTableView()
    }

    private func createContextMenu() -> UIMenu {
        let editMenuItem = UIAction(title: "Edit recipe", image: SFSymbols.editRecipe, handler: self.editRecipe)
        let groceriesMenuItem = UIAction(title: "Add to grocery list", image: SFSymbols.groceries, handler: self.addToGroceryList)
        let deleteMenuItem = UIAction(title: "Delete recipe", image: SFSymbols.trash, attributes: .destructive, handler: self.deleteRecipe)

        let menuA = UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: [editMenuItem, groceriesMenuItem])
        let menuB = UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: [deleteMenuItem])
        return UIMenu(title: "", image: nil, identifier: nil, options: [], children: [menuA, menuB])
    }

    private func configureViewController() {
        self.view.backgroundColor = .systemBackground

        self.navigationItem.largeTitleDisplayMode = .never

        let contextMenuItem = UIBarButtonItem(image: SFSymbols.contextMenu, menu: self.createContextMenu())
        let groceriesMenuItem = UIBarButtonItem(title: nil, image: SFSymbols.groceries, target: self, action: #selector(self.addToGroceryList))
        self.navigationItem.rightBarButtonItems = [contextMenuItem, groceriesMenuItem]
    }

    private func configureTableView() {
        self.view.addSubview(self.tableView)

        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.tableView.contentInset.bottom = 16
        self.tableView.frame = self.view.bounds
        self.tableView.allowsSelection = false
        self.tableView.separatorStyle = .none
        self.tableView.removeExcessCells()

        self.tableView.register(
            RecipeTitleCell.self,
            forCellReuseIdentifier: RecipeTitleCell.reuseID)
        self.tableView.register(
            RecipeIngredientCell.self,
            forCellReuseIdentifier: RecipeIngredientCell.reuseID)
        self.tableView.register(
            RecipeInstructionCell.self,
            forCellReuseIdentifier: RecipeInstructionCell.reuseID)
    }

    func editRecipe(_ action: UIAction) {
        let destVC = RecipeFormVC(style: .edit)
        destVC.delegate = self
        destVC.set(recipe: self.recipe)

        let navController = UINavigationController(rootViewController: destVC)
        self.present(navController, animated: true)
    }

    func deleteRecipe(_ action: UIAction) {
        let alert = RBDeleteRecipeItemAlert(item: .recipe(self.recipe)) { [weak self] () in
            guard let self = self else { return }
            self.delegate?.didDeleteRecipe(recipe: self.recipe)
        }
        self.present(alert, animated: true)
    }

    @objc func addToGroceryList(_ action: UIAction) {
        let alert = RBAddGroceriesAlert(recipe: self.recipe)
        self.present(alert, animated: true)
    }
}

extension RecipeVC: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        // title and ingredients and instructions
        return 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = Section(rawValue: section)!
        switch section {
        case .title:
            return 1
        case .ingredients:
            return self.recipe.ingredients.count
        case .instructions:
            return self.recipe.instructions.count
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = Section(rawValue: section)!
        return section.title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = Section(rawValue: indexPath.section)!
        let i = indexPath.row

        switch section {
        case .title:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: RecipeTitleCell.reuseID) as! RecipeTitleCell
            cell.set(title: self.recipe.title)
            return cell

        case .ingredients:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: RecipeIngredientCell.reuseID) as! RecipeIngredientCell
            cell.set(ingredient: self.recipe.ingredients[i])
            return cell

        case .instructions:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: RecipeInstructionCell.reuseID) as! RecipeInstructionCell
            cell.set(n: i + 1, instruction: self.recipe.instructions[i])
            return cell
        }
    }
}

extension RecipeVC: RecipeFormVCDelegate {

    func didSaveRecipe(style: RecipeFormVC.Style, recipe: Recipe) {
        // NOTE: ignoring style, should always be edit
        if let error = State.manager.updateRecipe(recipe: recipe) {
            self.presentErrorAlert(error)
        } else {
            self.recipe = recipe
            self.tableView.reloadData()
        }
    }
}
