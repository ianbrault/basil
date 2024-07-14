//
//  GroceryListVC.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/22/23.
//

import UIKit

class GroceryListVC: UIViewController {

    let tableView = UITableView()

    var previousCount = 0

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureNavigationBar()

        if State.manager.groceryList.isEmpty {
            self.showEmptyStateView(.groceries, in: self.view)
        } else {
            self.removeEmptyStateView(in: self.view)
        }

        if State.manager.groceryList.count != self.previousCount {
            self.tableView.reloadData()
        }
        self.previousCount = State.manager.groceryList.count
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
}

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
        State.manager.groceryList.toggleComplete(at: indexPath)
        State.manager.storeGroceryList()

        tableView.beginUpdates()
        tableView.reloadRows(at: [indexPath], with: .none)
        tableView.endUpdates()
    }
}
