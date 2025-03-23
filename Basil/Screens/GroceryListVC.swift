//
//  GroceryListVC.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/22/23.
//

import UIKit

//
// Displays a list of groceries
// Allows users to add/delete groceries and check/reorder items
//
class GroceryListVC: UIViewController {
    static let reuseID = "GroceryCell"

    typealias DataSource = UITableViewDiffableDataSource<Int, Ingredient>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Int, Ingredient>

    private let tableView = UITableView()
    private let feedback = UISelectionFeedbackGenerator()

    private lazy var dataSource = DataSource(tableView: self.tableView) { (tableView, indexPath, grocery) -> UITableViewCell? in
        var cell = tableView.dequeueReusableCell(withIdentifier: GroceryListVC.reuseID, for: indexPath)

        var configuration = cell.defaultContentConfiguration()
        configuration.text = grocery.toString()
        if grocery.complete {
            configuration.image = SFSymbols.checkmarkCircleFill
            configuration.imageProperties.tintColor = StyleGuide.colors.primary
        } else {
            configuration.image = SFSymbols.circle
            configuration.imageProperties.tintColor = StyleGuide.colors.secondaryText
        }
        cell.contentConfiguration = configuration

        return cell
    }

    func applySnapshot(reload identifiers: [Ingredient] = [], animatingDifferences: Bool = true) {
        var snapshot = Snapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(State.manager.groceryList.items, toSection: 0)
        snapshot.reloadItems(identifiers)
        self.dataSource.apply(snapshot, animatingDifferences: animatingDifferences)

        if State.manager.groceryList.isEmpty {
            self.showEmptyStateView(.groceries, in: self.view)
        } else {
            self.removeEmptyStateView(in: self.view)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = "Groceries"
        self.applySnapshot(animatingDifferences: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureViewController()
        self.configureTableView()
    }

    private func configureViewController() {
        self.view.backgroundColor = .systemBackground

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addGrocery))
        let deleteButton = UIBarButtonItem(title: nil, image: SFSymbols.trash, target: self, action: #selector(self.deleteGroceries))
        self.navigationItem.rightBarButtonItems = [deleteButton, addButton]
    }

    private func configureTableView() {
        self.view.addSubview(self.tableView)

        self.tableView.frame = self.view.bounds
        self.tableView.delegate = self
        self.tableView.separatorStyle = .none
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.removeExcessCells()

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: GroceryListVC.reuseID)
    }

    @objc func addGrocery(_ action: UIAction) {
        let alert = TextFieldAlert(
            title: "New Ingredient",
            message: "Enter the ingredient for the grocery list",
            placeholder: "ex. ½ red onion",
            confirmText: "Save"
        ) { [weak self] (text) in
            guard let self else { return }

            let ingredient = IngredientParser.shared.parse(string: text)
            State.manager.addToGroceryList(ingredient)
            self.applySnapshot(reload: [ingredient])
        }
        alert.autocapitalizationType = UITextAutocapitalizationType.none
        self.present(alert, animated: true)
    }

    @objc func editGrocery(_ action: UIAction, at indexPath: IndexPath) {
        let grocery = State.manager.groceryList.grocery(at: indexPath)

        let alert = TextFieldAlert(
            title: "Edit Ingredient",
            message: "Enter the ingredient for the grocery list",
            placeholder: "ex. ½ red onion",
            confirmText: "Save"
        ) { [weak self] (text) in
            guard let self else { return }

            let grocery = IngredientParser.shared.parse(string: text)
            let newIndexPath = State.manager.replaceGrocery(at: indexPath, with: grocery)
            let newGrocery = State.manager.groceryList.grocery(at: newIndexPath)
            self.applySnapshot(reload: [newGrocery])
        }
        alert.text = grocery.toString()
        alert.autocapitalizationType = UITextAutocapitalizationType.none
        self.present(alert, animated: true)
    }

    @objc func deleteGrocery(_ action: UIAction, at indexPath: IndexPath) {
        let title = "Are you sure you want to delete this grocery?"
        let alert = DeleteAlert(title: title) { [weak self] () in
            guard let self = self else { return }

            State.manager.removeGrocery(at: indexPath)
            self.applySnapshot()
        }
        self.present(alert, animated: true)
    }

    @objc func deleteGroceries(_ action: UIAction) {
        let title = "Are you sure you want to delete all groceries?"
        let alert = DeleteAlert(title: title) { [weak self] () in
            guard let self = self else { return }

            State.manager.removeAllGroceries()
            self.applySnapshot()
        }
        self.present(alert, animated: true)
    }
}


extension GroceryListVC: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let newIndexPath = State.manager.groceryList.toggleComplete(at: indexPath)
        State.manager.storeGroceryList()

        let grocery = State.manager.groceryList.grocery(at: newIndexPath)
        self.applySnapshot(reload: [grocery])
        self.feedback.selectionChanged()
    }

    func tableView(
        _ tableView: UITableView,
        contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] (_) in
            guard let self = self else { return UIMenu() }
            let editAction = UIAction(title: "Edit grocery", image: SFSymbols.editRecipe) { (action) in
                self.editGrocery(action, at: indexPath)
            }
            let deleteAction = UIAction(title: "Delete grocery", image: SFSymbols.trash, attributes: .destructive) { (action) in
                self.deleteGrocery(action, at: indexPath)
            }
            return UIMenu(title: "", children: [editAction, deleteAction])
        }
    }
}
