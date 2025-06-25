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
class RecipeVC: UITableViewController {
    static let titleReuseID = "RecipeCell__Title"
    static let ingredientsReuseID = "RecipeCell__Ingredients"
    static let instructionsReuseID = "RecipeCell__Instructions"
    static let sectionReuseID = "RecipeCell__Section"

    protocol Delegate: AnyObject {
        func didDeleteRecipe(recipe: Recipe)
    }

    enum Section: Int, CaseIterable {
        case title
        case ingredients
        case instructions
    }

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

        let contextMenuItem = self.createBarButton(image: SFSymbols.contextMenu, menu: self.createContextMenu())
        let cookingMenuItem = self.createBarButton(image: SFSymbols.cook, action: #selector(self.startCooking))
        let groceriesMenuItem = self.createBarButton(image: SFSymbols.groceries, action: #selector(self.addToGroceryList))
        self.navigationItem.rightBarButtonItems = [contextMenuItem, cookingMenuItem, groceriesMenuItem]
    }

    private func configureTableView() {
        self.tableView.allowsSelection = false
        self.tableView.contentInset.bottom = 16
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.sectionHeaderTopPadding = 10
        self.tableView.separatorStyle = .none
        self.tableView.removeExcessCells()

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: RecipeVC.titleReuseID)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: RecipeVC.ingredientsReuseID)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: RecipeVC.instructionsReuseID)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: RecipeVC.sectionReuseID)
    }

    func editRecipe(_ action: UIAction) {
        let viewController = RecipeFormVC(style: .edit)
        viewController.delegate = self
        viewController.set(recipe: self.recipe)

        let navigationController = NavigationController(rootViewController: viewController)
        self.present(navigationController, animated: true)
    }

    func deleteRecipe(_ action: UIAction) {
        let alert = DeleteRecipeItemAlert(item: .recipe(self.recipe)) { [weak self] in
            guard let self = self else { return }
            self.delegate?.didDeleteRecipe(recipe: self.recipe)
        }
        self.present(alert, animated: true)
    }

    private func tryParseSectionHeader(at indexPath: IndexPath) -> String? {
        guard let section = Section(rawValue: indexPath.section) else { return nil }

        var text: String
        switch section {
        case .title:
            return nil
        case .ingredients:
            text = self.recipe.ingredients[indexPath.row].toString()
        case .instructions:
            text = self.recipe.instructions[indexPath.row]
        }

        if text.starts(with: Recipe.sectionHeader) {
            return text.replacingOccurrences(of: Recipe.sectionHeader, with: "").trim()
        }
        return nil
    }

    @objc func addToGroceryList(_ action: UIAction) {
        let alert = AddGroceriesAlert(recipe: self.recipe)
        self.present(alert, animated: true)
    }

    @objc func startCooking(_ action: UIAction) {
        if let tabBar = self.tabBarController as? TabBarController {
            tabBar.addRecipeToCookingView(recipe: self.recipe)
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
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

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else { return UITableViewCell() }

        if let sectionHeader = self.tryParseSectionHeader(at: indexPath) {
            let cell = tableView.dequeueReusableCell(withIdentifier: RecipeVC.sectionReuseID)!
            var content = cell.defaultContentConfiguration()
            content.text = sectionHeader
            content.directionalLayoutMargins = .zero
            content.textProperties.color = StyleGuide.colors.secondaryText
            content.textProperties.font = StyleGuide.fonts.sectionHeader
            cell.contentConfiguration = content
            return cell
        }

        var cell: UITableViewCell
        switch section {
        case .title:
            cell = tableView.dequeueReusableCell(withIdentifier: RecipeVC.titleReuseID)!
            var content = cell.defaultContentConfiguration()
            content.text = self.recipe.title
            content.textProperties.font = .systemFont(ofSize: 24, weight: .bold)
            content.textProperties.lineBreakMode = .byWordWrapping
            cell.contentConfiguration = content
        case .ingredients:
            cell = tableView.dequeueReusableCell(withIdentifier: RecipeVC.ingredientsReuseID)!
            var content = ListContentConfiguration(style: .unordered)
            content.text = self.recipe.ingredients[indexPath.row].toString()
            cell.contentConfiguration = content
        case .instructions:
            cell = tableView.dequeueReusableCell(withIdentifier: RecipeVC.instructionsReuseID)!
            var content = ListContentConfiguration(style: .ordered)
            content.text = self.recipe.instructions[indexPath.row]
            content.row = indexPath.row + 1  // FIXME: this should be made relative to the section
            cell.contentConfiguration = content
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let _ = self.tryParseSectionHeader(at: indexPath) {
            return StyleGuide.tableCellHeight - 12
        } else {
            return UITableView.automaticDimension
        }
    }
}

extension RecipeVC: RecipeFormVC.Delegate {

    func didSaveRecipe(style: RecipeFormVC.Style, recipe: Recipe) {
        guard style == .edit else { return }
        if let error = State.manager.updateRecipe(recipe: recipe) {
            self.presentErrorAlert(error)
        } else {
            self.recipe = recipe
            self.tableView.reloadData()
        }
    }
}
