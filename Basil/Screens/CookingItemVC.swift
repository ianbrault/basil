//
//  CookingItemVC.swift
//  Basil
//
//  Created by Ian Brault on 3/21/25.
//

import UIKit

//
// Individual page view for CookingVC
// Contains ingredients and instructions for a recipe that is being cooked
//
class CookingItemVC: UIViewController {
    static let ingredientReuseID = "CookingIngredientCell"
    static let instructionReuseID = "CookingInstructionCell"

    enum Section: Int, CaseIterable {
        case ingredients
        case instructions
    }

    var recipe: Recipe
    private var instructionState: [Bool]

    private let tableView = UITableView()
    private let feedback = UISelectionFeedbackGenerator()

    init(recipe: Recipe) {
        self.recipe = recipe
        self.instructionState = recipe.instructions.map { _ in false }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = StyleGuide.colors.background
        self.configureTableView()
    }

    private func configureTableView() {
        self.view.addSubview(self.tableView)

        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .none
        self.tableView.removeExcessCells()

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: CookingItemVC.ingredientReuseID)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: CookingItemVC.instructionReuseID)

        self.tableView.pinToSides(of: self.view)
        self.tableView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
    }
}

extension CookingItemVC: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        switch section {
        case .ingredients:
            return self.recipe.ingredients.count
        case .instructions:
            return self.recipe.instructions.count
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = Section(rawValue: section) else { return nil }
        switch section {
        case .ingredients:
            return "Ingredients"
        case .instructions:
            return "Instructions"
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else { return UITableViewCell() }
        switch section {
        case .ingredients:
            let cell = tableView.dequeueReusableCell(withIdentifier: CookingItemVC.ingredientReuseID)!
            var content = ListContentConfiguration(style: .unordered)
            content.text = self.recipe.ingredients[indexPath.row].toString()
            cell.contentConfiguration = content
            return cell
        case .instructions:
            let cell = tableView.dequeueReusableCell(withIdentifier: CookingItemVC.instructionReuseID)!
            var configuration = CookingContentConfiguration()
            configuration.text = self.recipe.instructions[indexPath.row]
            configuration.selected = self.instructionState[indexPath.row]
            cell.contentConfiguration = configuration
            return cell
        }
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard indexPath.section == Section.instructions.rawValue else { return nil }
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == Section.instructions.rawValue else { return }
        self.instructionState[indexPath.row] = !self.instructionState[indexPath.row]
        self.feedback.selectionChanged()
        self.tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}
