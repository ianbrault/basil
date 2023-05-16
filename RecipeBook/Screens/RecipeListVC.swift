//
//  RecipeListVC.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/22/23.
//

import UIKit

class RecipeListVC: UIViewController {

    let tableView = UITableView()

    var folder: RecipeFolder!
    var items: [RecipeItem] = []

    init(folderId: UUID) {
        super.init(nibName: nil, bundle: nil)
        self.folder = State.manager.getItem(uuid: folderId).intoFolder()!
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
        self.title = self.folder.name.isEmpty ? "Recipes" : self.folder.name
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.navigationBar.tintColor = .systemYellow

        let appearance = UINavigationBarAppearance()
        appearance.largeTitleTextAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 32, weight: .bold),
        ]
        self.navigationController?.navigationBar.standardAppearance = appearance
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

    private func createAddButtonContextMenu() -> UIMenu {
        let recipeMenuItems = [
            UIAction(title: "Add new recipe", image: SFSymbols.addRecipe, handler: self.addNewRecipe),
            UIAction(title: "Import recipe", image: SFSymbols.importRecipe, handler: self.importRecipe),
        ]
        let folderMenuItems = [
            UIAction(title: "Add new folder", image: SFSymbols.folder, handler: self.addNewFolder),
        ]

        let recipeMenu = UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: recipeMenuItems)
        let folderMenu = UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: folderMenuItems)
        return UIMenu(title: "", image: nil, identifier: nil, options: [], children: [recipeMenu, folderMenu])
    }

    private func createRecipeLongPressContextMenu(recipe: Recipe) -> UIContextMenuConfiguration {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { (_) in
            let editAction = UIAction(title: "Edit recipe", image: SFSymbols.editRecipe) { (_) in
                let destVC = RecipeFormVC(style: .edit)
                destVC.delegate = self
                destVC.set(recipe: recipe)

                let navController = UINavigationController(rootViewController: destVC)
                self.present(navController, animated: true)
            }
            let moveAction = UIAction(title: "Move to folder", image: SFSymbols.folder) { (_) in
                // TODO: unimplemented
                print("move")
            }
            let deleteAction = UIAction(title: "Delete recipe", image: SFSymbols.trash, attributes: .destructive) { (_) in
                let alert = RBDeleteRecipeItemAlert(item: .recipe(recipe)) { [weak self] () in
                    guard let self = self else { return }

                    if let error = State.manager.deleteItem(uuid: recipe.uuid) {
                        self.presentErrorAlert(error)
                    } else {
                        self.removeItem(uuid: recipe.uuid)
                    }
                }
                self.present(alert, animated: true)
            }
            return UIMenu(title: "", children: [editAction, moveAction, deleteAction])
        }
    }

    private func createFolderLongPressContextMenu(folder: RecipeFolder) -> UIContextMenuConfiguration {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { (_) in
            let editAction = UIAction(title: "Edit folder", image: SFSymbols.editRecipe) { (_) in
                let alert = RBTextFieldAlert(
                    title: "Edit folder",
                    placeholder: "Enter folder name",
                    text: folder.name,
                    confirmButtonText: "Save"
                ) { [weak self] (text) in
                    guard let self else { return }
                    folder.name = text
                    if let error = State.manager.updateFolder(folder: folder) {
                        self.presentErrorAlert(error)
                    } else {
                        // update the items array with the updated folder
                        if let indexPath = self.findItem(uuid: folder.uuid) {
                            self.items[indexPath.row] = .folder(folder)
                            DispatchQueue.main.async {
                                self.tableView.reloadRows(at: [indexPath], with: .automatic)
                            }
                        } else {
                            self.presentErrorAlert(.missingRecipe(folder.uuid))
                        }
                    }
                }
                self.present(alert, animated: true)
            }
            let moveAction = UIAction(title: "Move to folder", image: SFSymbols.folder) { (_) in
                // TODO: unimplemented
                print("move")
            }
            let deleteAction = UIAction(title: "Delete folder", image: SFSymbols.trash, attributes: .destructive) { (_) in
                let alert = RBDeleteRecipeItemAlert(item: .folder(folder)) { [weak self] () in
                    guard let self = self else { return }

                    if let error = State.manager.deleteItem(uuid: folder.uuid) {
                        self.presentErrorAlert(error)
                    } else {
                        self.removeItem(uuid: folder.uuid)
                    }
                }
                self.present(alert, animated: true)
            }
            return UIMenu(title: "", children: [editAction, moveAction, deleteAction])
        }
    }

    func loadItems() {
        let folderItems = State.manager.getFolderItems(uuid: self.folder.uuid)!
        // show the empty state view if there are no items
        if folderItems.isEmpty {
            self.showEmptyStateView(in: self.view)
        } else {
            self.items = folderItems.sorted(by: RecipeItem.sort)
            // reload table view data on the main thread
            DispatchQueue.main.async {
                self.tableView.reloadData()
                // ensure that the table view is brought to the front in case the empty state
                // view is still there
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

    func insertItem(item: RecipeItem) {
        // find the sorted position for the item
        let pos = self.items.firstIndex { RecipeItem.sort(item, $0) } ?? self.items.endIndex
        let indexPath = IndexPath(row: pos, section: 0)

        self.items.insert(item, at: pos)
        DispatchQueue.main.async {
            self.removeEmptyStateView(in: self.view)
            self.tableView.insertRows(at: [indexPath], with: .automatic)
        }
    }

    func removeItem(uuid: UUID) {
        // find the item using the given UUID
        if let indexPath = self.findItem(uuid: uuid) {
            self.items.remove(at: indexPath.row)
            DispatchQueue.main.async {
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                // if this was the last recipe, show the empty state view
                if self.items.isEmpty {
                    self.showEmptyStateView(in: self.view)
                }
            }
        } else {
            self.presentErrorAlert(.missingRecipe(uuid))
        }
    }

    func addNewRecipe(_ action: UIAction) {
        let destVC = RecipeFormVC(style: .new)
        destVC.delegate = self
        destVC.folderId = self.folder.uuid

        let navController = UINavigationController(rootViewController: destVC)
        self.present(navController, animated: true)
    }

    func addNewFolder(_ action: UIAction) {
        let alert = RBTextFieldAlert(
            title: "Add a new folder",
            placeholder: "Enter folder name",
            confirmButtonText: "Create"
        ) { [weak self] (text) in
            guard let self else { return }

            let folder = RecipeFolder(folderId: self.folder.uuid, name: text)
            if let error = State.manager.addFolder(folder: folder) {
                self.presentErrorAlert(error)
            } else {
                self.insertItem(item: .folder(folder))
            }
        }
        self.present(alert, animated: true)
    }

    func importRecipe(_ action: UIAction) {
        let alert = RBTextFieldAlert(
            title: "Import a recipe",
            placeholder: "URL",
            confirmButtonText: "Import"
        ) { [weak self] (_) in
            guard let self else { return }
            // TODO: not implemented
            self.notImplementedAlert()
        }
        self.present(alert, animated: true)
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
        let item = self.items[indexPath.row]
        switch item {
        case .recipe(let recipe):
            let recipeVC = RecipeVC()
            recipeVC.recipe = recipe
            recipeVC.delegate = self
            self.navigationController?.pushViewController(recipeVC, animated: true)

        case .folder(let folder):
            let recipeListVC = RecipeListVC(folderId: folder.uuid)
            self.navigationController?.pushViewController(recipeListVC, animated: true)
        }
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let item = self.items[indexPath.row]

        let contextItem = UIContextualAction(style: .destructive, title: "Delete") {  (action, view, actionPerformed) in
            let alert = RBDeleteRecipeItemAlert(item: item) { [weak self] () in
                guard let self = self else { return }

                if let error = State.manager.deleteItem(uuid: item.uuid) {
                    self.presentErrorAlert(error)
                    actionPerformed(false)
                } else {
                    self.removeItem(uuid: item.uuid)
                    actionPerformed(true)
                }
            }
            self.present(alert, animated: true)
        }

        return UISwipeActionsConfiguration(actions: [contextItem])
    }

    func tableView(
        _ tableView: UITableView,
        contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        let item = self.items[indexPath.row]
        switch item {
        case .recipe(let recipe):
            return self.createRecipeLongPressContextMenu(recipe: recipe)
        case .folder(let folder):
            return self.createFolderLongPressContextMenu(folder: folder)
        }
    }
}

extension RecipeListVC: RecipeFormVCDelegate {

    func didSaveRecipe(style: RecipeFormVC.Style, recipe: Recipe) {
        switch style {
        case .new:
            if let error = State.manager.addRecipe(recipe: recipe) {
                self.presentErrorAlert(error)
            } else {
                self.insertItem(item: .recipe(recipe))
            }

        case .edit:
            if let error = State.manager.updateRecipe(recipe: recipe) {
                self.presentErrorAlert(error)
            } else {
                // update the items array with the new recipe contents
                if let indexPath = self.findItem(uuid: recipe.uuid) {
                    self.items[indexPath.row] = .recipe(recipe)
                } else {
                    self.presentErrorAlert(.missingRecipe(recipe.uuid))
                }
            }
        }
    }
}

extension RecipeListVC: RecipeVCDelegate {

    func didDeleteRecipe(recipe: Recipe) {
        // remove the recipe view first
        self.navigationController?.popViewController(animated: true)

        if let error = State.manager.deleteItem(uuid: recipe.uuid) {
            self.presentErrorAlert(error)
        } else {
            self.removeItem(uuid: recipe.uuid)
        }
    }
}
