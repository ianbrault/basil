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
        Recipe(title: "Roasted Brussels Sprouts", ingredients: [], instructions: []),
        Recipe(title: "Pear Torte", ingredients: [], instructions: []),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewController()
        configureTableView()
    }

    func configureViewController() {
        view.backgroundColor = .systemBackground
        title = "Recipes"
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    func configureTableView() {
        view.addSubview(tableView)

        tableView.frame = view.bounds
        tableView.delegate = self
        tableView.dataSource = self
        tableView.removeExcessCells()

        tableView.register(RecipeCell.self, forCellReuseIdentifier: RecipeCell.reuseID)
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
        let recipe = recipes[indexPath.row]

        let destVC = RecipeVC()
        destVC.recipe = recipe
        let navController = UINavigationController(rootViewController: destVC)
        present(navController, animated: true)
    }
}
