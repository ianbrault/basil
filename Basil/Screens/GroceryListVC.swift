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

    private let tableView = UITableView()
    private let feedback = UISelectionFeedbackGenerator()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        State.manager.groceryList.mergeGroceries()
        if PersistenceManager.shared.sortCheckedGroceries {
            State.manager.groceryList.sortCheckedGroceries()
        }
        State.manager.storeGroceryList()

        self.tableView.reloadData()
        if State.manager.groceryList.isEmpty {
            self.tableView.backgroundView = EmptyStateView(.groceries)
        } else {
            self.tableView.backgroundView = nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureViewController()
        self.configureTableView()
    }

    private func configureViewController() {
        self.title = "Groceries"
        self.view.backgroundColor = StyleGuide.colors.background

        let addButton = self.createBarButton(systemItem: .add, action: #selector(self.addGrocery))
        let deleteButton = self.createBarButton(image: SFSymbols.trash, action: #selector(self.deleteGroceries))
        self.navigationItem.rightBarButtonItems = [deleteButton, addButton]
    }

    private func configureTableView() {
        self.tableView.dataSource = self
        self.tableView.dataSource = self
        self.tableView.allowsSelection = false
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.tableHeaderView = UIView()
        self.tableView.removeExcessCells()

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: GroceryListVC.reuseID)

        self.view.addPinnedSubview(self.tableView, keyboardBottom: true)

        // tap to dismiss keyboard
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        self.tableView.addGestureRecognizer(gesture)
    }

    private func deleteGrocery(at indexPath: IndexPath) {
        State.manager.removeGrocery(at: indexPath)
        self.tableView.deleteRows(at: [indexPath], with: .automatic)
    }

    private func modifyGrocery(_ text: String, at indexPath: IndexPath) {
        let grocery = IngredientParser.shared.parse(string: text)
        State.manager.modifyGrocery(at: indexPath, with: grocery)
    }

    private func toggleGrocery(at indexPath: IndexPath) {
        let grocery = State.manager.groceryList.grocery(at: indexPath)
        State.manager.groceryList.toggleComplete(at: indexPath)

        self.feedback.selectionChanged()
        self.tableView.reloadRows(at: [indexPath], with: .none)

        if PersistenceManager.shared.sortCheckedGroceries {
            State.manager.groceryList.sortCheckedGroceries()
            if let newIndexPath = State.manager.groceryList.indexOf(grocery: grocery) {
                self.tableView.moveRow(at: indexPath, to: newIndexPath)
            }
        }

        State.manager.storeGroceryList()
    }

    @objc func dismissKeyboard(_ action: UIAction) {
        self.tableView.endEditing(true)
    }

    @objc func addGrocery(_ action: UIAction) {
        // if the final grocery is empty, simply re-focus the final empty grocery
        // this can happen if the add button is pressed twice without entering any text in between
        if State.manager.groceryList.last?.isEmpty ?? false {
            let indexPath = IndexPath(row: State.manager.groceryList.count - 1, section: 0)
            self.tableView.cellForRow(at: indexPath)?.contentView.becomeFirstResponder()
            return
        }

        let indexPath = IndexPath(row: State.manager.groceryList.count, section: 0)
        State.manager.addToGroceryList(.empty())
        // add and focus the new input row
        self.tableView.performBatchUpdates({ [weak self] () in
            self?.tableView.insertRows(at: [indexPath], with: .automatic)
        }, completion: { [weak self] (_) in
            self?.tableView.cellForRow(at: indexPath)?.contentView.becomeFirstResponder()
        })
    }

    @objc func deleteGroceries(_ action: UIAction) {
        let title = "Are you sure you want to delete all groceries?"
        let alert = DeleteAlert(title: title) { [weak self] () in
            guard let self = self else { return }

            State.manager.removeAllGroceries()
            self.tableView.backgroundView = EmptyStateView(.groceries)
            self.tableView.reloadData()
        }
        self.present(alert, animated: true)
    }
}

extension GroceryListVC: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return State.manager.groceryList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: GroceryListVC.reuseID, for: indexPath)
        let grocery = State.manager.groceryList.grocery(at: indexPath)

        var configuration = TextViewContentConfiguration()
        configuration.text = grocery.toString()
        configuration.imageSize = 28
        configuration.imageToTextPadding = 8
        if grocery.complete {
            configuration.image = SFSymbols.checkmarkCircleFill
            configuration.tintColor = StyleGuide.colors.primary
        } else {
            configuration.image = SFSymbols.circle
            configuration.tintColor = StyleGuide.colors.tertiaryText
        }
        configuration.onChange = { [weak self] (text) in
            guard let index = self?.tableView.indexPath(for: cell) else { return }
            self?.modifyGrocery(text, at: index)
        }
        configuration.onEndEditing = { [weak self] (text) in
            // remove if done editing and the grocery is empty
            guard let index = self?.tableView.indexPath(for: cell) else { return }
            if text.isEmpty {
                self?.deleteGrocery(at: index)
            }
        }
        configuration.onImageTap = { [weak self] () in
            guard let index = self?.tableView.indexPath(for: cell) else { return }
            self?.toggleGrocery(at: index)
        }

        cell.contentConfiguration = configuration
        cell.separatorInset.left = configuration.contentInset + configuration.imageSize + configuration.imageToTextPadding

        return cell
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let contextItem = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, actionPerformed) in
            self?.deleteGrocery(at: indexPath)
            actionPerformed(true)
        }
        return UISwipeActionsConfiguration(actions: [contextItem])
    }
}
