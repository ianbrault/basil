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

    var folderId: UUID!
    var items: [RecipeItem] = []

    init(folderId: UUID) {
        super.init(nibName: nil, bundle: nil)
        self.folderId = folderId
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureNavigationBar()
        self.loadItems()
        // check-in with the server if it has not been done already
        if !State.manager.serverPoked {
            self.establishServerCommunication()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureViewController()
        self.configureTableView()
    }

    private func configureNavigationBar() {
        let folder = State.manager.getFolder(uuid: self.folderId)!
        self.title = folder.name.isEmpty ? "Recipes" : folder.name
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

        // create the bar button items
        self.addButton = UIBarButtonItem(systemItem: .add, menu: self.createAddButtonContextMenu())
        self.editButton = UIBarButtonItem(title: nil, image: SFSymbols.contextMenu, target: self, action: #selector(self.enableEditMode))
        self.doneButton = UIBarButtonItem(title: nil, image: SFSymbols.checkmarkCircle, target: self, action: #selector(self.disableEditMode))
        self.moveButton = UIBarButtonItem(title: nil, image: SFSymbols.folder, target: self, action: #selector(self.moveSelectedItems))
        self.moveButton.isEnabled = false
        self.deleteButton = UIBarButtonItem(title: nil, image: SFSymbols.trash, target: self, action: #selector(self.deleteSelectedItems))
        self.deleteButton.tintColor = .systemRed
        self.deleteButton.isEnabled = false

        // start with the add/edit buttons in the navigation bar
        // these will be swapped out when the table edit mode is toggled
        self.navigationItem.rightBarButtonItems = [self.editButton, self.addButton]
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

            let editAction = UIAction(title: "Edit recipe", image: SFSymbols.editRecipe) { (action) in
                self.editRecipe(action, recipe: recipe)
            }
            let moveAction = UIAction(title: "Move to folder", image: SFSymbols.folder) { (action) in
                self.moveItemToFolder(action, uuid: recipe.uuid)
            }
            let deleteAction = UIAction(title: "Delete recipe", image: SFSymbols.trash, attributes: .destructive) { (action) in
                self.deleteItem(action, item: .recipe(recipe))
            }
            return UIMenu(title: "", children: [editAction, moveAction, deleteAction])
        }
    }

    private func createFolderLongPressContextMenu(folder: RecipeFolder) -> UIContextMenuConfiguration {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] (_) in
            guard let self = self else { return UIMenu() }

            let editAction = UIAction(title: "Edit folder", image: SFSymbols.editRecipe) { (action) in
                self.editFolder(action, folder: folder)
            }
            let moveAction = UIAction(title: "Move to folder", image: SFSymbols.folder) { (action) in
                self.moveItemToFolder(action, uuid: folder.uuid)

            }
            let deleteAction = UIAction(title: "Delete folder", image: SFSymbols.trash, attributes: .destructive) { (action) in
                self.deleteItem(action, item: .folder(folder))
            }
            return UIMenu(title: "", children: [editAction, moveAction, deleteAction])
        }
    }

    private func showNoConnectionView() {
        DispatchQueue.main.async {
            let errorView = RBNoConnectionView(in: self.view)
            self.view.window?.addSubview(errorView)
            self.view.window?.bringSubviewToFront(errorView)
        }
    }

    private func showProcessingView() {
        DispatchQueue.main.async {
            // show the view while the local data is pushed to the server
            let processingView = RBProcessingView(in: self.view)
            self.view.window?.addSubview(processingView)
            self.view.window?.bringSubviewToFront(processingView)
        }
    }

    private func hideProcessingView() {
        DispatchQueue.main.async {
            for subview in self.view.window?.subviews ?? [] {
                if let processingView = subview as? RBProcessingView {
                    processingView.dismissView()
                }
            }
        }
    }

    private func establishServerCommunication() {
        State.manager.serverPoked = true
        API.pokeServer { (error) in
            if let _ = error {
                self.showNoConnectionView()
            } else {
                State.manager.serverCommunicationEstablished = true
                if PersistenceManager.shared.needsToUpdateServer {
                    self.showProcessingView()
                    API.updateUser { (error) in
                        self.hideProcessingView()
                        if let error {
                            DispatchQueue.main.async {
                                self.presentErrorAlert(error)
                            }
                        } else {
                            PersistenceManager.shared.needsToUpdateServer = false
                        }
                    }
                }
            }
        }
    }

    func loadItems() {
        let folder = State.manager.getFolder(uuid: self.folderId)!
        // show the empty state view if there are no items
        if folder.recipes.isEmpty && folder.subfolders.isEmpty {
            self.showEmptyStateView(.recipes, in: self.view)
        } else {
            // load subfolder/recipe items using the IDs from the folder
            var folderItems: [RecipeItem] = []
            for folderId in folder.subfolders {
                if let folder = State.manager.getFolder(uuid: folderId) {
                    folderItems.append(.folder(folder))
                } else {
                    self.presentErrorAlert(.missingItem(.folder, folderId))
                }
            }
            for recipeId in folder.recipes {
                if let recipe = State.manager.getRecipe(uuid: recipeId) {
                    folderItems.append(.recipe(recipe))
                } else {
                    self.presentErrorAlert(.missingItem(.recipe, recipeId))
                }
            }
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
                    self.showEmptyStateView(.recipes, in: self.view)
                }
            }
        } else {
            // this branch should never be hit
            // item type is ambiguous but just assume recipe
            self.presentErrorAlert(.missingItem(.recipe, uuid))
        }
    }

    func removeItems(uuids: [UUID]) {
        // find the items using the given UUIDs
        var indexPaths: [IndexPath] = []
        for uuid in uuids {
            if let indexPath = self.findItem(uuid: uuid) {
                indexPaths.append(indexPath)
            } else {
                // this branch should never be hit
                // item type is ambiguous but just assume recipe
                self.presentErrorAlert(.missingItem(.recipe, uuid))
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
                self.showEmptyStateView(.recipes, in: self.view)
            }
        }
    }

    func addNewRecipe(_ action: UIAction) {
        let destVC = RecipeFormVC(style: .new)
        destVC.delegate = self
        destVC.folderId = self.folderId

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

            let folder = RecipeFolder(folderId: self.folderId, name: text)
            if let error = State.manager.addFolder(folder: folder) {
                self.presentErrorAlert(error)
            } else {
                self.insertItem(item: .folder(folder))
            }
        }
        self.present(alert, animated: true)
    }

    func editRecipe(_ action: UIAction, recipe: Recipe) {
        let destVC = RecipeFormVC(style: .edit)
        destVC.delegate = self
        destVC.set(recipe: recipe)

        let navController = UINavigationController(rootViewController: destVC)
        self.present(navController, animated: true)
    }

    func editFolder(_ action: UIAction, folder: RecipeFolder) {
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
                    self.presentErrorAlert(.missingItem(.folder, folder.uuid))
                }
            }
        }
        self.present(alert, animated: true)
    }

    func moveItemToFolder(_ action: UIAction, uuid: UUID) {
        let destVC = FolderTreeVC(currentFolder: self.folderId) { [weak self] (selectedFolder) in
            guard let self = self else { return }

            if let error = State.manager.moveItemToFolder(uuid: uuid, folderId: selectedFolder.uuid) {
                self.presentErrorAlert(error)
            } else if selectedFolder.uuid != self.folderId {
                // item has been moved to a folder on another screen so remove it
                self.removeItem(uuid: uuid)
            }
        }
        let navController = UINavigationController(rootViewController: destVC)
        self.present(navController, animated: true)
    }

    func deleteItem(_ action: UIAction, item: RecipeItem) {
        let alert = RBDeleteRecipeItemAlert(item: item) { () in
            if let error = State.manager.deleteItem(uuid: item.uuid) {
                self.presentErrorAlert(error)
            } else {
                self.removeItem(uuid: item.uuid)
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
            Network.get(text) { (response) in
                let result = response.flatMap { (body) in
                    NYTRecipeParser.parse(body: body, folderId: self.folderId)
                }
                DispatchQueue.main.async {
                    switch result {
                    case .success(let recipe):
                        if let error = State.manager.addRecipe(recipe: recipe) {
                            self.presentErrorAlert(error)
                        } else {
                            self.insertItem(item: .recipe(recipe))
                        }
                    case .failure(let error):
                        self.presentErrorAlert(error)
                    }
                }
            }
        }
        self.present(alert, animated: true)
    }

    @objc func enableEditMode(_ action: UIAction? = nil) {
        if self.items.isEmpty {
            return
        }
        self.tableView.setEditing(true, animated: true)
        // navigation bar should contain the delete and move and done buttons when edit mode is enabled
        self.navigationItem.rightBarButtonItems = [self.doneButton, self.moveButton, self.deleteButton]
    }

    @objc func disableEditMode(_ action: UIAction? = nil) {
        self.tableView.setEditing(false, animated: true)
        // navigation bar should contain the add and edit buttons when edit mode is disabled
        self.navigationItem.rightBarButtonItems = [self.editButton, self.addButton]
    }

    @objc func moveSelectedItems(_ action: UIAction) {
        if let selectedRows = tableView.indexPathsForSelectedRows, !selectedRows.isEmpty {
            let uuids = selectedRows.map { self.items[$0.row] }.map { $0.uuid }

            let destVC = FolderTreeVC(currentFolder: self.folderId) { [weak self] (selectedFolder) in
                guard let self = self else { return }

                if let error = State.manager.moveItemsToFolder(uuids: uuids, folderId: selectedFolder.uuid) {
                    self.presentErrorAlert(error)
                } else if selectedFolder.uuid != self.folderId {
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
                    DispatchQueue.main.async {
                        self.tableView.reloadRows(at: [indexPath], with: .automatic)
                    }
                } else {
                    self.presentErrorAlert(.missingItem(.recipe, recipe.uuid))
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
