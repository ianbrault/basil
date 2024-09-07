//
//  RecipeVC.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/8/23.
//

import UIKit

//
// Displays a recipe with its ingredients list and instructions
//
class RecipeVC: UIViewController {
    static let reuseID = "RecipeCell"

    protocol Delegate: AnyObject {
        func didDeleteRecipe(recipe: Recipe)
    }

    enum Section: Int, CaseIterable {
        case title
        case ingredients
        case instructions
    }

    private let tableView = UITableView()

    private var recipe: Recipe
    weak var delegate: Delegate?

    init(recipe: Recipe) {
        self.recipe = recipe
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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

        self.tableView.frame = self.view.bounds
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.contentInset.bottom = 16
        self.tableView.allowsSelection = false
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.separatorStyle = .none
        self.tableView.sectionHeaderTopPadding = 10
        self.tableView.removeExcessCells()

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: RecipeVC.reuseID)
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
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
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
        guard let section = Section(rawValue: section) else { return nil }
        switch section {
        case .title:
            return nil
        case .ingredients:
            return "Ingredients"
        case .instructions:
            return "Instructions"
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = Section(rawValue: indexPath.section)!
        let cell = tableView.dequeueReusableCell(withIdentifier: RecipeVC.reuseID)!

        switch section {
        case .title:
            var content = cell.defaultContentConfiguration()
            content.text = self.recipe.title
            content.textProperties.font = .systemFont(ofSize: 24, weight: .bold)
            cell.contentConfiguration = content
        case .ingredients:
            var content = ListContentConfiguration(style: .unordered)
            content.text = self.recipe.ingredients[indexPath.row].toString()
            cell.contentConfiguration = content
        case .instructions:
            var content = ListContentConfiguration(style: .ordered)
            content.text = self.recipe.instructions[indexPath.row]
            content.row = indexPath.row + 1
            cell.contentConfiguration = content
        }

        return cell
    }
}

extension RecipeVC: RecipeFormVC.Delegate {

    func didSaveRecipe(style: RecipeFormVC.FormStyle, recipe: Recipe) {
        // NOTE: ignoring style, should always be edit
        if let error = State.manager.updateRecipe(recipe: recipe) {
            self.presentErrorAlert(error)
        } else {
            self.recipe = recipe
            self.tableView.reloadData()
        }
    }
}
