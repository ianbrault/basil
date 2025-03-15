//
//  RecipeListVC.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/22/23.
//

import UIKit

//
// Displays a list of recipes and folders
// Allows users to add/delete/move recipes
//
class RecipeListVC: UIViewController {
    static let reuseID = "RecipeListCell"

    private var addButton: UIBarButtonItem!
    private var editButton: UIBarButtonItem!
    private var doneButton: UIBarButtonItem!
    private var moveButton: UIBarButtonItem!
    private var deleteButton: UIBarButtonItem!

    private var folderId: UUID
    private var isRoot: Bool
    private var loadErrors: [RBError] = []
    private var items: [RecipeItem] = []
    private var searchResults: [RecipeItem] = []

    private let tableView = UITableView()
    private let searchController = UISearchController(searchResultsController: nil)

    typealias DataSource = UITableViewDiffableDataSource<Int, RecipeItem>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Int, RecipeItem>

    private var isSearching: Bool {
        guard let text = self.searchController.searchBar.text else { return false }
        return !text.isEmpty
    }

    private lazy var dataSource = DataSource(tableView: self.tableView) { (tableView, indexPath, item) -> UITableViewCell? in
        let cell = tableView.dequeueReusableCell(withIdentifier: RecipeListVC.reuseID, for: indexPath)

        var content = cell.defaultContentConfiguration()
        content.imageProperties.tintColor = StyleGuide.colors.primary
        content.textProperties.lineBreakMode = .byTruncatingTail
        content.textProperties.numberOfLines = 1

        switch item {
        case .recipe(let recipe):
            cell.accessoryType = .none
            content.image = nil
            content.text = recipe.title
        case .folder(let folder):
            cell.accessoryType = .disclosureIndicator
            content.image = SFSymbols.folder
            content.text = folder.name
        }

        cell.contentConfiguration = content
        return cell
    }

    init(folderId: UUID) {
        self.folderId = folderId
        self.isRoot = folderId == State.manager.root
        super.init(nibName: nil, bundle: nil)
        self.loadItems()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func loadItems() {
        guard let folder = State.manager.getFolder(uuid: self.folderId) else {
            // this should never happen but including as a fail-safe
            self.title = "Recipes"
            self.items.removeAll()
            self.showEmptyStateView(.recipes, in: self.view)
            return
        }
        self.title = folder.name.isEmpty ? "Recipes" : folder.name
        // load subfolder/recipe items using the IDs from the folder
        var folderItems: [RecipeItem] = []
        for folderId in folder.subfolders {
            if let folder = State.manager.getFolder(uuid: folderId) {
                folderItems.append(.folder(folder))
            } else {
                self.loadErrors.append(.missingItem(.folder, folderId))
            }
        }
        for recipeId in folder.recipes {
            if let recipe = State.manager.getRecipe(uuid: recipeId) {
                folderItems.append(.recipe(recipe))
            } else {
                self.loadErrors.append(.missingItem(.recipe, recipeId))
            }
        }
        self.items = folderItems.sorted(by: RecipeItem.sort)
    }

    func updateItemsForSearchText() {
        guard let text = self.searchController.searchBar.text?.trim() else { return }
        if text.isEmpty {
            self.searchResults = self.items
        } else {
            self.searchResults = State.manager.itemsMatchingText(text).sorted(by: RecipeItem.sort)
        }
    }

    func applySnapshot(reload identifiers: [RecipeItem] = [], animatingDifferences: Bool = true) {
        var snapshot = Snapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(self.searchResults)
        snapshot.reloadItems(identifiers)
        self.dataSource.apply(snapshot, animatingDifferences: animatingDifferences)

        if self.items.isEmpty {
            self.showEmptyStateView(.recipes, in: self.view)
        } else {
            self.removeEmptyStateView(in: self.view)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureViewController()
        self.configureTableView()
        self.configureSearchController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // if the user info has changed since the view was last loaded, refresh the root folder
        if State.manager.userChanged {
            State.manager.userChanged = false
            if self.isRoot {
                self.folderId = State.manager.root!
            } else {
                // if this is not the root folder, return to the root
                self.navigationController?.popToRootViewController(animated: true)
                return
            }
        }
        self.loadItems()
        self.updateItemsForSearchText()
        self.applySnapshot(animatingDifferences: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        // show any errors that occurred when loading items
        for error in self.loadErrors {
            self.presentErrorAlert(error)
        }
        self.loadErrors.removeAll()
    }

    private func configureViewController() {
        self.view.backgroundColor = StyleGuide.colors.background

        // create the bar button items
        self.addButton = UIBarButtonItem(systemItem: .add, menu: self.createAddButtonContextMenu())
        self.editButton = UIBarButtonItem(title: nil, image: SFSymbols.contextMenu, target: self, action: #selector(self.enableEditMode))
        self.doneButton = UIBarButtonItem(title: nil, image: SFSymbols.checkmarkCircle, target: self, action: #selector(self.disableEditMode))
        self.moveButton = UIBarButtonItem(title: nil, image: SFSymbols.folder, target: self, action: #selector(self.moveSelectedItems))
        self.moveButton.isEnabled = false
        self.deleteButton = UIBarButtonItem(title: nil, image: SFSymbols.trash, target: self, action: #selector(self.deleteSelectedItems))
        self.deleteButton.tintColor = StyleGuide.colors.error
        self.deleteButton.isEnabled = false

        // start with the add/edit buttons in the navigation bar
        // these will be swapped out when the table edit mode is toggled
        self.navigationItem.rightBarButtonItems = [self.editButton, self.addButton]
    }

    private func configureTableView() {
        self.view.addSubview(self.tableView)

        self.tableView.frame = self.view.bounds
        self.tableView.delegate = self
        self.tableView.allowsMultipleSelection = true
        self.tableView.allowsMultipleSelectionDuringEditing = true
        self.tableView.tintColor = StyleGuide.colors.primary
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.removeExcessCells()

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: RecipeListVC.reuseID)
    }

    private func configureSearchController() {
        self.searchController.searchResultsUpdater = self
        self.searchController.searchBar.placeholder = "Search for recipes or folders"
        self.searchController.searchBar.autocapitalizationType = .none
        self.searchController.obscuresBackgroundDuringPresentation = false

        self.navigationItem.searchController = self.searchController
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
            let editAction = UIAction(title: "Edit recipe", image: SFSymbols.editRecipe) { (action) in
                self?.editRecipe(action, recipe: recipe)
            }
            let moveAction = UIAction(title: "Move to folder", image: SFSymbols.folder) { (action) in
                self?.moveItemToFolder(action, uuid: recipe.uuid)
            }
            let deleteAction = UIAction(title: "Delete recipe", image: SFSymbols.trash, attributes: .destructive) { (action) in
                self?.deleteItem(action, item: .recipe(recipe))
            }
            return UIMenu(title: "", children: [editAction, moveAction, deleteAction])
        }
    }

    private func createFolderLongPressContextMenu(folder: RecipeFolder) -> UIContextMenuConfiguration {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] (_) in
            let editAction = UIAction(title: "Edit folder", image: SFSymbols.editRecipe) { (action) in
                self?.editFolder(action, folder: folder)
            }
            let moveAction = UIAction(title: "Move to folder", image: SFSymbols.folder) { (action) in
                self?.moveItemToFolder(action, uuid: folder.uuid)

            }
            let deleteAction = UIAction(title: "Delete folder", image: SFSymbols.trash, attributes: .destructive) { (action) in
                self?.deleteItem(action, item: .folder(folder))
            }
            return UIMenu(title: "", children: [editAction, moveAction, deleteAction])
        }
    }

    func insertItem(item: RecipeItem) {
        // find the sorted position for the item
        let pos = self.items.firstIndex { RecipeItem.sort(item, $0) } ?? self.items.endIndex
        self.items.insert(item, at: pos)
        self.updateItemsForSearchText()
        self.applySnapshot()
    }

    func removeItem(uuid: UUID) {
        // find the item using the given UUID
        if let indexPath = self.items.findItem(uuid: uuid) {
            self.items.remove(at: indexPath.row)
        }
        if let indexPath = self.searchResults.findItem(uuid: uuid) {
            self.searchResults.remove(at: indexPath.row)
        }
        self.updateItemsForSearchText()
        self.applySnapshot()
    }

    func removeItems(uuids: [UUID]) {
        // remove the items using the given UUIDs
        for uuid in uuids {
            if let indexPath = self.items.findItem(uuid: uuid) {
                self.items.remove(at: indexPath.row)
            }
            if let indexPath = self.searchResults.findItem(uuid: uuid) {
                self.searchResults.remove(at: indexPath.row)
            }
        }
        self.updateItemsForSearchText()
        self.applySnapshot()
    }

    func addNewRecipe(_ action: UIAction) {
        let destVC = RecipeFormVC(style: .new)
        destVC.delegate = self
        destVC.folderId = self.folderId

        let navController = UINavigationController(rootViewController: destVC)
        self.present(navController, animated: true)
    }

    func addNewFolder(_ action: UIAction) {
        let alert = TextFieldAlert(
            title: "New Folder",
            message: "Enter a name for this folder",
            placeholder: "Name",
            confirmText: "Save"
        ) { [weak self] (text) in
            let folder = RecipeFolder(folderId: self?.folderId, name: text)
            if let error = State.manager.addFolder(folder: folder) {
                self?.presentErrorAlert(error)
            } else {
                self?.insertItem(item: .folder(folder))
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
        let alert = TextFieldAlert(
            title: "Edit Folder",
            message: "Enter a name for this folder",
            placeholder: "Name",
            confirmText: "Save"
        ) { [weak self] (text) in
            guard let self else { return }
            folder.name = text
            if let error = State.manager.updateFolder(folder: folder) {
                self.presentErrorAlert(error)
            } else {
                // update the items array with the updated folder
                let item = RecipeItem.folder(folder)
                if let indexPath = self.items.findItem(uuid: folder.uuid) {
                    self.items[indexPath.row] = item
                }
                if let indexPath = self.searchResults.findItem(uuid: folder.uuid) {
                    self.searchResults[indexPath.row] = item
                }
                self.updateItemsForSearchText()
                self.applySnapshot(reload: [item])
            }
        }
        alert.text = folder.name
        self.present(alert, animated: true)
    }

    func moveItemToFolder(_ action: UIAction, uuid: UUID) {
        let destVC = FolderTreeVC(currentFolder: self.folderId) { [weak self] (selectedFolder) in
            if let error = State.manager.moveItemToFolder(uuid: uuid, folderId: selectedFolder.uuid) {
                self?.presentErrorAlert(error)
            } else if selectedFolder.uuid != self?.folderId {
                // item has been moved to a folder on another screen so remove it
                self?.removeItem(uuid: uuid)
            }
        }
        let navController = UINavigationController(rootViewController: destVC)
        self.present(navController, animated: true)
    }

    func deleteItem(_ action: UIAction, item: RecipeItem) {
        let alert = DeleteRecipeItemAlert(item: item) { [weak self] () in
            if let error = State.manager.deleteItem(uuid: item.uuid) {
                self?.presentErrorAlert(error)
            } else {
                self?.removeItem(uuid: item.uuid)
            }
        }
        self.present(alert, animated: true)
    }

    func importRecipe(_ action: UIAction) {
        let alert = TextFieldAlert(
            title: "Import Recipe",
            message: "Enter the URL of the recipe",
            placeholder: "URL",
            confirmText: "Import"
        ) { [weak self] (text) in
            guard let self else { return }
            Network.get(text) { (response) in
                let result = response.flatMap { (body) in
                    NYTRecipeParser.parse(body: body, folderId: self.folderId)
                }
                DispatchQueue.main.async {
                    switch result {
                    case .success(let recipe):
                        // open the recipei in an editing window to allow the user to change before adding
                        let destVC = RecipeFormVC(style: .new)
                        destVC.delegate = self
                        destVC.set(recipe: recipe)

                        let navController = UINavigationController(rootViewController: destVC)
                        self.present(navController, animated: true)

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
                if let error = State.manager.moveItemsToFolder(uuids: uuids, folderId: selectedFolder.uuid) {
                    self?.presentErrorAlert(error)
                } else if selectedFolder.uuid != self?.folderId {
                    // items have been moved to a folder on another screen so remove them
                    self?.removeItems(uuids: uuids)
                    // disable edit mode once the action has completed
                    self?.disableEditMode()
                }
            }
            let navController = UINavigationController(rootViewController: destVC)
            self.present(navController, animated: true)
        }
    }

    @objc func deleteSelectedItems(_ action: UIAction) {
        if let selectedRows = self.tableView.indexPathsForSelectedRows, !selectedRows.isEmpty {
            let uuids = selectedRows.map { self.items[$0.row] }.map { $0.uuid }
            let title = "Are you sure you want to delete these \(uuids.count) items?"

            let alert = DeleteAlert(title: title) { [weak self] () in
                if let error = State.manager.deleteItems(uuids: uuids) {
                    self?.presentErrorAlert(error)
                } else {
                    self?.removeItems(uuids: uuids)
                    // disable edit mode once the action has completed
                    self?.disableEditMode()
                }
            }
            self.present(alert, animated: true)
        }
    }

    @objc func showSettingsView(_ action: UIAction) {
        let destVC = SettingsVC()
        let navController = UINavigationController(rootViewController: destVC)
        self.present(navController, animated: true)
    }
}

extension RecipeListVC: UITableViewDelegate {

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
        // index path is relative to search results
        let item = self.searchResults[indexPath.row]
        switch item {
        case .recipe(let recipe):
            let recipeVC = RecipeVC(recipe: recipe)
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
        // only allow swipe actions outside of search results
        guard !self.isSearching else { return nil }

        let item = self.items[indexPath.row]
        let contextItem = UIContextualAction(style: .destructive, title: "Delete") {  (action, view, actionPerformed) in
            let alert = DeleteRecipeItemAlert(item: item) { [weak self] () in
                if let error = State.manager.deleteItem(uuid: item.uuid) {
                    self?.presentErrorAlert(error)
                    actionPerformed(false)
                } else {
                    self?.removeItem(uuid: item.uuid)
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
        // index path is relative to search results
        let item = self.searchResults[indexPath.row]
        switch item {
        case .recipe(let recipe):
            return self.createRecipeLongPressContextMenu(recipe: recipe)
        case .folder(let folder):
            return self.createFolderLongPressContextMenu(folder: folder)
        }
    }
}

extension RecipeListVC: RecipeFormVC.Delegate {

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
                let item = RecipeItem.recipe(recipe)
                if let indexPath = self.items.findItem(uuid: recipe.uuid) {
                    self.items[indexPath.row] = item
                }
                if let indexPath = self.searchResults.findItem(uuid: recipe.uuid) {
                    self.searchResults[indexPath.row] = item
                }
                self.updateItemsForSearchText()
                self.applySnapshot(reload: [item])
            }
        }
    }
}

extension RecipeListVC: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        self.updateItemsForSearchText()
        self.applySnapshot()
    }
}

extension RecipeListVC: RecipeVC.Delegate {

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

extension Array<RecipeItem> {

    func findItem(uuid: UUID) -> IndexPath? {
        var indexPath: IndexPath? = nil
        for (index, item) in self.enumerated() {
            if item.uuid == uuid {
                indexPath = IndexPath(row: index, section: 0)
                break
            }
        }
        return indexPath
    }
}
