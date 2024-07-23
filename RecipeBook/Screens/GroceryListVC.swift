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

    typealias DataSource = UITableViewDiffableDataSource<Int, Grocery>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Int, Grocery>

    private let tableView = UITableView()

    private lazy var dataSource = DataSource(tableView: self.tableView) { (tableView, indexPath, grocery) -> GroceryCell? in
        let cell = tableView.dequeueReusableCell(withIdentifier: GroceryCell.reuseID, for: indexPath) as? GroceryCell
        cell?.set(grocery: grocery)
        return cell
    }

    func applySnapshot(reload identifiers: [Grocery] = [], animatingDifferences: Bool = true) {
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
        self.configureNavigationBar()
        self.applySnapshot(animatingDifferences: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureViewController()
        self.configureTableView()
    }

    private func configureNavigationBar() {
        self.title = "Groceries"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.navigationBar.tintColor = .systemYellow
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
        self.tableView.separatorStyle = .none
        self.tableView.delegate = self
        self.tableView.removeExcessCells()

        self.tableView.register(GroceryCell.self, forCellReuseIdentifier: GroceryCell.reuseID)
    }

    @objc func addGrocery(_ action: UIAction) {
        // TODO: unimplemented
    }

    @objc func deleteGroceries(_ action: UIAction) {
        let title = "Are you sure you want to delete all groceries?"
        let alert = RBDeleteAlert(title: title) { [weak self] () in
            guard let self = self else { return }

            State.manager.clearGroceryList()
            self.applySnapshot()
        }
        self.present(alert, animated: true)
    }
}


extension GroceryListVC: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let grocery = State.manager.groceryList.grocery(at: indexPath)
        grocery.toggleComplete()
        if grocery.complete {
            // move from the incomplete list to the complete list
            State.manager.groceryList.remove(at: indexPath)
            State.manager.groceryList.complete.insert(grocery, at: 0)
        } else {
            // move from the complete list to the incomplete list
            State.manager.groceryList.remove(at: indexPath)
            State.manager.groceryList.incomplete.add(grocery)
        }

        State.manager.storeGroceryList()
        self.applySnapshot(reload: [grocery])
    }
}
