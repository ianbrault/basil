//
//  FolderTreeVC.swift
//  RecipeBook
//
//  Created by Ian Brault on 5/15/23.
//

import UIKit

//
// Displays a tree visualizing the recipe folder hierarchy, used to select a folder
//
class FolderTreeVC: UITableViewController {
    static let reuseID = "FolderTreeCell"

    struct Item {
        let folder: RecipeFolder
        let indentLevel: Int
    }

    private var items: [Item] = []
    private var currentFolder: UUID
    private var completionHander: ((RecipeFolder) -> Void)

    init(currentFolder: UUID, completionHandler: @escaping (RecipeFolder) -> Void) {
        self.currentFolder = currentFolder
        self.completionHander = completionHandler
        super.init(nibName: nil, bundle: nil)
        self.loadFolderTree()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func getFolderItems(folder: RecipeFolder, indentLevel: Int) -> [Item] {
        let subfolders = folder.subfolders.filterMap { State.manager.getFolder(uuid: $0) }.sorted { $0.name < $1.name }
        return subfolders.map { Item(folder: $0, indentLevel: indentLevel) }
    }

    private func loadFolderTree() {
        // start with the root
        guard let root = State.manager.root, let rootFolder = State.manager.getFolder(uuid: root) else { return }
        self.items.append(Item(folder: rootFolder, indentLevel: 0))

        var queue = self.getFolderItems(folder: rootFolder, indentLevel: 1)
        while let item = queue.popFirst() {
            self.items.append(item)
            // and then add sub-folders to the queue
            let subitems = self.getFolderItems(folder: item.folder, indentLevel: item.indentLevel + 1)
            queue.insert(contentsOf: subitems, at: 0)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Move to folder"
        self.navigationItem.rightBarButtonItem = self.createBarButton(systemItem: .cancel, action: #selector(self.dismissSelf))
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.reuseID)
        self.tableView.removeExcessCells()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FolderTreeVC.reuseID)!
        let item = self.items[indexPath.row]
        let isEnabled = item.folder.uuid != self.currentFolder

        var content = cell.defaultContentConfiguration()
        content.image = SFSymbols.folder
        content.imageProperties.tintColor = isEnabled ? StyleGuide.colors.primary : .systemGray3
        content.text = item.folder.name.isEmpty ? "Recipes" : item.folder.name

        cell.contentConfiguration = content
        cell.indentationLevel = item.indentLevel * 2
        cell.isUserInteractionEnabled = isEnabled

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = self.items[indexPath.row]
        self.dismissSelf()
        self.completionHander(item.folder)
    }
}
