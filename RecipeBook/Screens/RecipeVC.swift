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
        case ingredients
        case instructions

        var title: String {
            switch self {
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureNavigationBar()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureViewController()
        self.configureTableView()
    }

    private func createContextMenu() -> UIMenu {
        let menuItems = [
            UIAction(title: "Edit recipe", image: SFSymbols.editRecipe, handler: self.editRecipe),
            UIAction(title: "Delete recipe", image: SFSymbols.trash, attributes: .destructive, handler: self.deleteRecipe),
        ]

        return UIMenu(title: "", image: nil, identifier: nil, options: [], children: menuItems)
    }

    private func configureNavigationBar() {
        self.title = recipe.title
        self.navigationController?.navigationBar.prefersLargeTitles = true

        let appearance = UINavigationBarAppearance()
        appearance.largeTitleTextAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 24, weight: .bold),
        ]
        self.navigationController?.navigationBar.standardAppearance = appearance

        // add a button for the context menu
        let menuButton = UIBarButtonItem(image: SFSymbols.contextMenu, menu: createContextMenu())
        
        self.navigationItem.rightBarButtonItem = menuButton
    }

    private func configureViewController() {
        self.view.backgroundColor = .systemBackground
    }

    private func configureTableView() {
        self.view.addSubview(self.tableView)

        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.tableView.frame = self.view.bounds
        self.tableView.allowsSelection = false
        self.tableView.separatorStyle = .none
        self.tableView.removeExcessCells()

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
        let alert = RBDeleteRecipeAlert { [weak self] () in
            guard let self = self else { return }
            self.delegate?.didDeleteRecipe(recipe: self.recipe)
        }
        self.present(alert.alertController, animated: true)
    }
}

extension RecipeVC: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        // ingredients and instructions
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = Section(rawValue: section)!
        switch section {
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
        case .ingredients:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: RecipeIngredientCell.reuseID) as! RecipeIngredientCell
            cell.set(ingredient: self.recipe.ingredients[i].item)
            return cell

        case .instructions:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: RecipeInstructionCell.reuseID) as! RecipeInstructionCell
            cell.set(n: i + 1, instruction: self.recipe.instructions[i].step)
            return cell
        }
    }
}

extension RecipeVC: RecipeFormVCDelegate {

    func didSaveRecipe(recipe: Recipe) {
        if let error = State.manager.updateRecipe(recipe: recipe) {
            self.presentErrorAlert(error)
        } else {
            self.recipe = recipe
            self.tableView.reloadData()
        }
    }
}
