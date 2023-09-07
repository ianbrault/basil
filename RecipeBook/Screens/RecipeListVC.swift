//
//  RecipeListVC.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/22/23.
//

import UIKit

class RecipeListVC: UIViewController {

    let tableView = UITableView()

    var addButton: UIBarButtonItem!
    var editButton: UIBarButtonItem!
    var doneButton: UIBarButtonItem!
    var moveButton: UIBarButtonItem!
    var deleteButton: UIBarButtonItem!
    var debugButton: UIBarButtonItem!

    var folder: RecipeFolder!
    var items: [RecipeItem] = []

    // set this flag to enable development mode debug features
    // NOTE: ensure that this is unset before releasing
    let development: Bool = true

    init(folderId: UUID) {
        super.init(nibName: nil, bundle: nil)
        self.folder = State.manager.getItem(uuid: folderId)!.intoFolder()!
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

        // create an add button to add new recipes
        self.addButton = UIBarButtonItem(systemItem: .add, menu: self.createAddButtonContextMenu())

        // create an edit button to enable edit mode on the table
        self.editButton = UIBarButtonItem(
            title: nil, image: SFSymbols.contextMenu, target: self, action: #selector(self.enableEditMode))

        // create a done button to disable edit mode on the table
        self.doneButton = UIBarButtonItem(
            title: nil, image: SFSymbols.checkmarkCircle, target: self, action: #selector(self.disableEditMode))

        // create a move button to move selected items
        self.moveButton = UIBarButtonItem(
            title: nil, image: SFSymbols.folder, target: self, action: #selector(self.moveSelectedItems))
        self.moveButton.isEnabled = false

        // create a delete button to delete selected items
        self.deleteButton = UIBarButtonItem(
            title: nil, image: SFSymbols.trash, target: self, action: #selector(self.deleteSelectedItems))
        self.deleteButton.tintColor = .systemRed
        self.deleteButton.isEnabled = false

        // create the "nuke" button to clear all state
        // NOTE: this will only be used in development mode
        self.debugButton = UIBarButtonItem(image: SFSymbols.bug, menu: self.createDevelopmentContextMenu())
        self.debugButton.tintColor = .systemGreen

        // start with the add/edit buttons in the navigation bar
        // these will be swapped out when the table edit mode is toggled
        if self.development {
            self.navigationItem.rightBarButtonItems = [self.editButton, self.addButton, self.debugButton]
        } else {
            self.navigationItem.rightBarButtonItems = [self.editButton, self.addButton]
        }
    }

    private func configureTableView() {
        self.view.addSubview(self.tableView)

        self.tableView.frame = self.view.bounds
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.removeExcessCells()

        self.tableView.allowsMultipleSelection = true
        self.tableView.allowsMultipleSelectionDuringEditing = true

        self.tableView.register(RecipeCell.self, forCellReuseIdentifier: RecipeCell.reuseID)
    }

    private func createDevelopmentContextMenu() -> UIMenu {
        let menuItems = [
            UIAction(title: "Factory restore", image: SFSymbols.atom, handler: self.factoryRestore),
            UIAction(title: "Seed recipes", image: SFSymbols.importRecipe, handler: self.seedRecipes),
        ]

        return UIMenu(title: "", image: nil, identifier: nil, options: [], children: menuItems)
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
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] (_) in
            guard let self = self else { return UIMenu() }

            let editAction = UIAction(title: "Edit recipe", image: SFSymbols.editRecipe) { (_) in
                let destVC = RecipeFormVC(style: .edit)
                destVC.delegate = self
                destVC.set(recipe: recipe)

                let navController = UINavigationController(rootViewController: destVC)
                self.present(navController, animated: true)
            }
            let moveAction = UIAction(title: "Move to folder", image: SFSymbols.folder) { (_) in
                let destVC = FolderTreeVC { [weak self] (selectedFolder) in
                    guard let self = self else { return }

                    if let error = State.manager.moveItemToFolder(uuid: recipe.uuid, folderId: selectedFolder.uuid) {
                        self.presentErrorAlert(error)
                    } else if selectedFolder.uuid != self.folder.uuid {
                        // item has been moved to a folder on another screen so remove it
                        self.removeItem(uuid: recipe.uuid)
                    }
                }
                let navController = UINavigationController(rootViewController: destVC)
                self.present(navController, animated: true)
            }
            let deleteAction = UIAction(title: "Delete recipe", image: SFSymbols.trash, attributes: .destructive) { (_) in
                let alert = RBDeleteRecipeItemAlert(item: .recipe(recipe)) { () in
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
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] (_) in
            guard let self = self else { return UIMenu() }

            let editAction = UIAction(title: "Edit folder", image: SFSymbols.editRecipe) { (_) in
                let alert = RBTextFieldAlert(
                    title: "Edit folder",
                    placeholder: "Enter folder name",
                    text: folder.name,
                    confirmButtonText: "Save"
                ) { (text) in
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
                let destVC = FolderTreeVC { (selectedFolder) in
                    if let error = State.manager.moveItemToFolder(uuid: folder.uuid, folderId: selectedFolder.uuid) {
                        self.presentErrorAlert(error)
                    } else if selectedFolder.uuid != self.folder.uuid {
                        // item has been moved to a folder on another screen so remove it
                        self.removeItem(uuid: folder.uuid)
                    }
                }
                let navController = UINavigationController(rootViewController: destVC)
                self.present(navController, animated: true)
            }
            let deleteAction = UIAction(title: "Delete folder", image: SFSymbols.trash, attributes: .destructive) { (_) in
                let alert = RBDeleteRecipeItemAlert(item: .folder(folder)) { () in
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

    func removeItems(uuids: [UUID]) {
        // find the items using the given UUIDs
        var indexPaths: [IndexPath] = []
        for uuid in uuids {
            if let indexPath = self.findItem(uuid: uuid) {
                indexPaths.append(indexPath)
            } else {
                self.presentErrorAlert(.missingRecipe(uuid))
            }
        }

        // remove the items from the list
        let rows = Set(indexPaths.map { $0.row })
        let newItems = self.items.enumerated().filter { !rows.contains($0.offset) }.map { $0.element }
        self.items = newItems
        DispatchQueue.main.async {
            self.tableView.deleteRows(at: indexPaths, with: .automatic)
            // if these were the last recipes, show the empty state view
            if self.items.isEmpty {
                self.showEmptyStateView(in: self.view)
            }
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
        ) { [weak self] (text) in
            guard let self else { return }

            // TODO: check if there is data on the clipboard
            HTTPGet(url: text) { [weak self] (result) in
                guard let self = self else { return }

                switch result {
                case .success(let body):
                    switch parseNYTRecipe(body: body, folderId: self.folder.uuid) {
                    case .success(let recipe):
                        DispatchQueue.main.async {
                            if let error = State.manager.addRecipe(recipe: recipe) {
                                self.presentErrorAlert(error)
                            } else {
                                self.insertItem(item: .recipe(recipe))
                            }
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            self.presentErrorAlert(error)
                        }
                    }

                case .failure(let error):
                    DispatchQueue.main.async {
                        self.presentErrorAlert(error)
                    }
                }
            }
        }
        self.present(alert, animated: true)
    }

    func factoryRestore(_ action: UIAction) {
        // NOTE: can only be used in development mode
        if !self.development { return }

        let alert = RBWarningAlert(
            message: "Are you sure you want to fully wipe all recipe data?",
            actionStyle: .destructive
        ) { [weak self] () in
            guard let self = self else { return }
            State.manager.clear()
            DispatchQueue.main.async {
                self.items = []
                self.tableView.reloadData()
                self.showEmptyStateView(in: self.view)
            }
        }
        self.present(alert, animated: true)
    }

    func debugRecipe(_ key: String, folderId: UUID) -> Recipe {
        return Recipe(
            uuid: UUID(),
            folderId: folderId,
            title: "Recipe \(key)",
            ingredients: [Ingredient(item: "item \(key)")],
            instructions: [Instruction(step: "instruction \(key)")]
        )
    }

    func debugFolder(_ key: String, folderId: UUID) -> RecipeFolder {
        return RecipeFolder(
            folderId: folderId,
            name: "Folder \(key)"
        )
    }

    func seedRecipes(_ action: UIAction) {
        // NOTE: can only be used in development mode
        if !self.development { return }

        let recipeA = self.debugRecipe("A", folderId: self.folder.uuid)
        let _ = State.manager.addRecipe(recipe: recipeA)
        let recipeB = self.debugRecipe("B", folderId: self.folder.uuid)
        let _ = State.manager.addRecipe(recipe: recipeB)
        let recipeC = self.debugRecipe("C", folderId: self.folder.uuid)
        let _ = State.manager.addRecipe(recipe: recipeC)

        let folderA = self.debugFolder("A", folderId: self.folder.uuid)
        let _ = State.manager.addFolder(folder: folderA)
        let recipeD = self.debugRecipe("D", folderId: folderA.uuid)
        let _ = State.manager.addRecipe(recipe: recipeD)

        let folderB = self.debugFolder("B", folderId: self.folder.uuid)
        let _ = State.manager.addFolder(folder: folderB)
        let recipeE = self.debugRecipe("E", folderId: folderB.uuid)
        let _ = State.manager.addRecipe(recipe: recipeE)
        let folderC = self.debugFolder("C", folderId: folderB.uuid)
        let _ = State.manager.addFolder(folder: folderC)
        let recipeF = self.debugRecipe("F", folderId: folderC.uuid)
        let _ = State.manager.addRecipe(recipe: recipeF)

        self.loadItems()
    }

    @objc func enableEditMode(_ action: UIAction? = nil) {
        self.tableView.setEditing(true, animated: true)
        // navigation bar should contain the delete and move and done buttons when edit mode is enabled
        self.navigationItem.rightBarButtonItems = [self.doneButton, self.moveButton, self.deleteButton]
    }

    @objc func disableEditMode(_ action: UIAction? = nil) {
        self.tableView.setEditing(false, animated: true)
        // navigation bar should contain the add and edit buttons when edit mode is disabled
        if self.development {
            self.navigationItem.rightBarButtonItems = [self.editButton, self.addButton, self.debugButton]
        } else {
            self.navigationItem.rightBarButtonItems = [self.editButton, self.addButton]
        }
    }

    @objc func moveSelectedItems(_ action: UIAction) {
        if let selectedRows = tableView.indexPathsForSelectedRows, !selectedRows.isEmpty {
            let uuids = selectedRows.map { self.items[$0.row] }.map { $0.uuid }

            let destVC = FolderTreeVC { [weak self] (selectedFolder) in
                guard let self = self else { return }

                if let error = State.manager.moveItemsToFolder(uuids: uuids, folderId: selectedFolder.uuid) {
                    self.presentErrorAlert(error)
                } else if selectedFolder.uuid != self.folder.uuid {
                    // items have been moved to a folder on another screen so remove them
                    self.removeItems(uuids: uuids)
                    // disable edit mode once the action has completed
                    self.disableEditMode()
                }
            }
            let navController = UINavigationController(rootViewController: destVC)
            self.present(navController, animated: true)
        }
    }

    @objc func deleteSelectedItems(_ action: UIAction) {
        if let selectedRows = tableView.indexPathsForSelectedRows, !selectedRows.isEmpty {
            let uuids = selectedRows.map { self.items[$0.row] }.map { $0.uuid }

            let alert = RBDeleteMultipleRecipeItemsAlertViewController(count: uuids.count) { [weak self] () in
                guard let self = self else { return }

                if let error = State.manager.deleteItems(uuids: uuids) {
                    self.presentErrorAlert(error)
                } else {
                    self.removeItems(uuids: uuids)
                    // disable edit mode once the action has completed
                    self.disableEditMode()
                }
            }
            self.present(alert, animated: true)
        }
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
        // prevent items from being opened while in edit mode
        if tableView.isEditing {
            let selected = tableView.indexPathsForSelectedRows?.count ?? 0
            // enable move/delete buttons if items are selected
            if selected > 0 {
                self.moveButton.isEnabled = true
                self.deleteButton.isEnabled = true
            }
            return
        }

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

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        // table should already be in edit mode, guard just in case
        if tableView.isEditing {
            let selected = tableView.indexPathsForSelectedRows?.count ?? 0
            // disable move/delete buttons if no more items are selected
            if selected == 0 {
                self.moveButton.isEnabled = false
                self.deleteButton.isEnabled = false
            }
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
