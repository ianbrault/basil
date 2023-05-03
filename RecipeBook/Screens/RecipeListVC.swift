//
//  RecipeListVC.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/22/23.
//

import UIKit

class RecipeListVC: UIViewController {

    let tableView = UITableView()

    var folderId: UUID!
    var items: [RecipeItem] = []

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureNavigationBar()
        self.loadItems()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureViewController()
        self.configureTableView()
    }

    private func configureNavigationBar() {
        self.title = "Recipes"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.navigationBar.tintColor = .systemYellow

        let appearance = UINavigationBarAppearance()
        appearance.largeTitleTextAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 32, weight: .bold),
        ]
        self.navigationController?.navigationBar.standardAppearance = appearance
    }

    private func createAddButtonContextMenu() -> UIMenu {
        let menuItems = [
            UIAction(title: "Add new recipe", image: SFSymbols.addRecipe, handler: self.addNewRecipe),
            UIAction(title: "Import recipe", image: SFSymbols.importRecipe, handler: self.importRecipe),
        ]

        return UIMenu(title: "", image: nil, identifier: nil, options: [], children: menuItems)
    }

    private func configureViewController() {
        self.view.backgroundColor = .systemBackground

        // add an add button to add new recipes
        let addButton = UIBarButtonItem(systemItem: .add, menu: createAddButtonContextMenu())
        self.navigationItem.rightBarButtonItem = addButton
    }

    private func configureTableView() {
        self.view.addSubview(self.tableView)

        self.tableView.frame = self.view.bounds
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.removeExcessCells()

        self.tableView.register(RecipeCell.self, forCellReuseIdentifier: RecipeCell.reuseID)
    }

    func loadItems() {
        // FIXME: filter out recipes until folders are supported cells
        let folderItems = State.manager.getFolderItems(uuid: self.folderId)!.filter { $0.isRecipe }

        // show the empty state view if there are no items
        if folderItems.isEmpty {
            self.showEmptyStateView(in: self.view)
        } else {
            self.items = folderItems
            // reload table view data on the main thread
            DispatchQueue.main.async {
                self.tableView.reloadData()
                // ensure that the table view is brought to the front in case the empty state view is still there
                self.view.bringSubviewToFront(self.tableView)
            }
        }
    }

    func findItem(uuid: UUID) -> IndexPath? {
        var indexPath: IndexPath? = nil
        for (index, item) in self.items.enumerated() {
            if item.uuid == uuid {
                indexPath = IndexPath(row: index, section: 0)
                break
            }
        }
        return indexPath
    }

    func addNewRecipe(_ action: UIAction) {
        let destVC = RecipeFormVC(style: .new)
        destVC.delegate = self
        destVC.folderId = self.folderId

        let navController = UINavigationController(rootViewController: destVC)
        self.present(navController, animated: true)
    }

    func importRecipe(_ action: UIAction) {
        let alert = RBTextFieldAlert(title: "Import a recipe", message: nil, placeholder: "URL")
        alert.delegate = self

        self.present(alert.alertController, animated: true)
    }
}

extension RecipeListVC: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecipeCell.reuseID) as! RecipeCell
        let item = self.items[indexPath.row]
        cell.set(item: item)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // TODO: add folder handling
        let item = self.items[indexPath.row]
        let recipe = item.intoRecipe()!
        let recipeVC = RecipeVC()
        recipeVC.recipe = recipe
        recipeVC.delegate = self

        self.navigationController?.pushViewController(recipeVC, animated: true)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        // TODO: add folder handling
        let item = self.items[indexPath.row]

        let contextItem = UIContextualAction(style: .destructive, title: "Delete") {  (action, view, actionPerformed) in
            let alert = RBDeleteRecipeAlert { [weak self] () in
                guard let self = self else { return }

                // save the initial items in case we get an error
                let previousItems = self.items

                self.items.remove(at: indexPath.row)
                if let error = State.manager.deleteRecipe(uuid: item.uuid) {
                    // restore the original items
                    self.items = previousItems
                    self.presentErrorAlert(error)
                    actionPerformed(false)
                } else {
                    self.tableView.deleteRows(at: [indexPath], with: .automatic)
                    // if this was the last recipe, show the empty state view
                    if self.items.isEmpty {
                        self.showEmptyStateView(in: self.view)
                    }
                    actionPerformed(true)
                }
            }
            self.present(alert.alertController, animated: true)
        }

        return UISwipeActionsConfiguration(actions: [contextItem])
    }
}

extension RecipeListVC: RecipeFormVCDelegate {

    func didSaveRecipe(recipe: Recipe) {
        // save the initial items in case we get an error
        let previousItems = self.items

        self.items.append(.recipe(recipe))
        if let error = State.manager.addRecipe(recipe: recipe) {
            // restore the original items
            self.items = previousItems
            self.presentErrorAlert(error)
        } else {
            self.removeEmptyStateView(in: self.view)
            self.tableView.reloadData()
        }
    }
}

extension RecipeListVC: RecipeVCDelegate {

    func didDeleteRecipe(recipe: Recipe) {
        // remove the recipe view first
        self.navigationController?.popViewController(animated: true)

        // save the initial items in case we get an error
        let previousItems = self.items

        if let indexPath = self.findItem(uuid: recipe.uuid) {
            self.items.remove(at: indexPath.row)
            if let error = State.manager.deleteRecipe(uuid: recipe.uuid) {
                // restore the original items
                self.items = previousItems
                self.presentErrorAlert(error)
            } else {
                DispatchQueue.main.async {
                    self.tableView.deleteRows(at: [indexPath], with: .automatic)
                    // if this was the last recipe, show the empty state view
                    if self.items.isEmpty {
                        self.showEmptyStateView(in: self.view)
                    }
                }
            }
        } else {
            self.presentErrorAlert(.missingRecipe(recipe.uuid))
        }
    }
}

extension RecipeListVC: RBTextFieldAlertDelegate {

    func didSubmitText(text: String) {
        self.notImplementedAlert()
    }
}
