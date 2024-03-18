//
//  GroceryListVC.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/22/23.
//

import UIKit

class GroceryListVC: UIViewController {

    let tableView = UITableView()

    var groceries: [Grocery] = []

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureNavigationBar()
        self.loadGroceries()
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

    private func loadGroceries() {
        self.groceries = State.manager.groceries
        // FIXME: DEBUG
        self.groceries = [
            Grocery(item: "Apples"),
            Grocery(item: "Bananas"),
            Grocery(item: "Cinnamon Toast Crunch"),
        ]
        if self.groceries.isEmpty {
            self.showEmptyStateView(.groceries, in: self.view)
        }
    }
}

extension GroceryListVC: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.groceries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: GroceryCell.reuseID) as! GroceryCell
        let grocery = self.groceries[indexPath.row]
        cell.set(grocery: grocery)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let grocery = self.groceries[indexPath.row]
        grocery.toggleComplete()
        State.manager.updateGroceries(groceries: self.groceries)

        tableView.beginUpdates()
        tableView.reloadRows(at: [indexPath], with: .automatic)
        tableView.endUpdates()
    }
}
