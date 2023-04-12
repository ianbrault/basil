//
//  RecipeVC.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/8/23.
//

import UIKit

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureNavigationBar()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureViewController()
        self.configureTableView()
    }

    private func configureNavigationBar() {
        self.title = recipe.title
        self.navigationController?.navigationBar.prefersLargeTitles = true

        let appearance = UINavigationBarAppearance()
        appearance.largeTitleTextAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 24, weight: .bold),
        ]
        self.navigationController?.navigationBar.standardAppearance = appearance
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
