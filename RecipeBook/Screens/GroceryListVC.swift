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

    let tableView = UITableView()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureNavigationBar()

        if State.manager.groceryList.isEmpty {
            self.showEmptyStateView(.groceries, in: self.view)
        } else {
            self.removeEmptyStateView(in: self.view)
        }
        self.tableView.reloadData()
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
        self.tableView.dataSource = self
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
            DispatchQueue.main.async {
                self.tableView.reloadData()
                // show the empty state view
                self.showEmptyStateView(.groceries, in: self.view)
            }
        }
        self.present(alert, animated: true)
    }
}

// TODO: consider using UITableViewDiffableDataSource instead
extension GroceryListVC: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return State.manager.groceryList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: GroceryCell.reuseID) as! GroceryCell
        let grocery = State.manager.groceryList.grocery(at: indexPath)
        cell.set(grocery: grocery)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // first toggle the completion and reload the row to see the update
        State.manager.groceryList.grocery(at: indexPath).toggleComplete()
        tableView.reloadRows(at: [indexPath], with: .none)

        let grocery = State.manager.groceryList.grocery(at: indexPath)
        if grocery.complete {
            let mergeWithExisting = State.manager.groceryList.complete.contains(grocery)
            // move from the incomplete list to the complete list
            State.manager.groceryList.remove(at: indexPath)
            State.manager.groceryList.complete.insert(grocery, at: 0)
            if mergeWithExisting {
                // let newIndex = State.manager.groceryList.indexOf(grocery: grocery)!
                tableView.deleteRows(at: [indexPath], with: .automatic)
                // FIXME: data needs to be reloaded
                // tableView.reloadRows(at: [newIndex], with: .automatic)
            } else {
                let newIndex = IndexPath(row: State.manager.groceryList.incomplete.count, section: 0)
                tableView.moveRow(at: indexPath, to: newIndex)
            }
        } else {
            let mergeWithExisting = State.manager.groceryList.incomplete.contains(grocery)
            // move from the complete list to the incomplete list
            State.manager.groceryList.remove(at: indexPath)
            State.manager.groceryList.incomplete.insert(grocery, at: 0)
            if mergeWithExisting {
                // let newIndex = State.manager.groceryList.indexOf(grocery: grocery)!
                tableView.deleteRows(at: [indexPath], with: .automatic)
                // FIXME: data needs to be reloaded
                // tableView.reloadRows(at: [newIndex], with: .automatic)
            } else {
                let newIndex = IndexPath(row: State.manager.groceryList.incomplete.count - 1, section: 0)
                tableView.moveRow(at: indexPath, to: newIndex)
            }
        }

        State.manager.storeGroceryList()
    }
}
