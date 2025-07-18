//
//  RecipePickerVC.swift
//  Basil
//
//  Created by Ian Brault on 7/11/25.
//

import UIKit

class RecipePickerVC: UITableViewController {
    static let reuseID = "RecipePickerCell"

    class Item: Hashable {
        let type: State.Item
        let name: String
        let uuid: UUID
        var expanded: Bool = false
        var selected: Bool = false
        var indent: Int = 0

        var identifier: String {
            return self.uuid.uuidString
        }

        init(from recipe: Recipe, selected: Bool = false, indent: Int = 0) {
            self.type = .recipe
            self.name = recipe.title
            self.uuid = recipe.uuid
            self.selected = selected
            self.indent = indent
        }

        init(from folder: RecipeFolder, indent: Int = 0) {
            self.type = .folder
            self.name = folder.name
            self.uuid = folder.uuid
            self.indent = indent
        }

        func hash(into hasher: inout Hasher) {
            return hasher.combine(self.identifier)
        }

        static func == (lhs: Item, rhs: Item) -> Bool {
            return lhs.uuid == rhs.uuid
        }
    }

    private var items: [Item] = []
    private var selected: Set<UUID> = []
    private var onCompletion: (([UUID]) -> Void)? = nil

    private let accessoryImageSize: CGFloat = 16
    private let folderImageSize = CGSize(width: 32, height: 32)
    private let checkboxImageSize = CGSize(width: 24, height: 24)

    init(title: String = "", selected: [UUID] = [], onCompletion: (([UUID]) -> Void)? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.title = title
        self.onCompletion = onCompletion
        self.loadItems(selected: selected)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func loadItems(selected: [UUID] = []) {
        self.selected = Set(selected)
        // only load top-level items initially
        guard let root = State.manager.root, let rootFolder = State.manager.getFolder(uuid: root) else { return }
        let folders = rootFolder.subfolders.filterMap { State.manager.getFolder(uuid: $0) }.sorted { $0.name < $1.name }
        for folder in folders {
            self.items.append(Item(from: folder))
        }
        let recipes = rootFolder.recipes.filterMap { State.manager.getRecipe(uuid: $0) }.sorted { $0.title < $1.title }
        for recipe in recipes {
            self.items.append(Item(from: recipe, selected: self.selected.contains(recipe.uuid)))
        }
        // expand folders so that all initially-selected items are shown
        for item in selected {
            let folderChain = State.manager.folderChain(for: item)
            for folder in folderChain {
                if folder == State.manager.root {
                    continue
                }
                if let itemIndex = self.items.firstIndex(where: { $0.uuid == folder }) {
                    self.expandFolder(at: IndexPath(row: itemIndex, section: 0))
                }
            }
        }
    }

    private func accessoryImage(_ image: UIImage?) -> UIImageView {
        let imageView = UIImageView(image: image)
        imageView.tintColor = StyleGuide.colors.primary
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.frame = CGRect(x: 0, y: 0, width: self.accessoryImageSize, height: self.accessoryImageSize)
        return imageView
    }

    private func toggleRecipe(at indexPath: IndexPath) {
        let item = self.items[indexPath.row]
        item.selected = !item.selected
        if item.selected {
            self.selected.insert(item.uuid)
        } else {
            self.selected.remove(item.uuid)
        }
        self.tableView.reloadRows(at: [indexPath], with: .none)
    }

    private func expandFolder(at indexPath: IndexPath) {
        let item = self.items[indexPath.row]
        guard !item.expanded, let folder = State.manager.getFolder(uuid: item.uuid) else { return }
        item.expanded = true
        self.tableView.reloadRows(at: [indexPath], with: .none)
        if folder.subfolders.isEmpty && folder.recipes.isEmpty {
            return
        }

        var subitems: [Item] = []
        let folders = folder.subfolders.filterMap { State.manager.getFolder(uuid: $0) }.sorted { $0.name < $1.name }
        for folder in folders {
            subitems.append(Item(from: folder, indent: item.indent + 1))
        }
        let recipes = folder.recipes.filterMap { State.manager.getRecipe(uuid: $0) }.sorted { $0.title < $1.title }
        for recipe in recipes {
            subitems.append(Item(from: recipe, selected: self.selected.contains(recipe.uuid), indent: item.indent + 1))
        }
        self.items.insert(contentsOf: subitems, at: indexPath.row + 1)
        self.tableView.insertRows(at: Self.indexPathRange(start: indexPath.row + 1, count: subitems.count), with: .automatic)
    }

    private func collapseFolder(at indexPath: IndexPath) {
        let item = self.items[indexPath.row]
        guard item.expanded, let folder = State.manager.getFolder(uuid: item.uuid) else { return }
        item.expanded = false
        self.tableView.reloadRows(at: [indexPath], with: .none)
        if folder.subfolders.isEmpty && folder.recipes.isEmpty {
            return
        }

        // first collapse all subfolders
        for subfolder in folder.subfolders {
            if let subitem = self.items.first(where: { $0.uuid == subfolder }), subitem.expanded {
                let subindex = self.items.firstIndex(of: subitem)!
                self.collapseFolder(at: IndexPath(row: subindex, section: 0))
            }
        }
        let nItems = folder.subfolders.count + folder.recipes.count
        self.items.removeSubrange((indexPath.row + 1)..<(indexPath.row + nItems + 1))
        self.tableView.deleteRows(at: Self.indexPathRange(start: indexPath.row + 1, count: nItems), with: .automatic)
    }

    @objc func done() {
        self.dismissSelf()
        self.onCompletion?(Array(self.selected))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.leftBarButtonItem = self.createBarButton(systemItem: .cancel, action: #selector(self.dismissSelf))
        self.navigationItem.rightBarButtonItem = self.createBarButton(systemItem: .done, action: #selector(self.done))

        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.reuseID)
        self.tableView.removeExcessCells()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // scroll to the first selected recipe
        if let index = self.items.firstIndex(where: { $0.selected }) {
            self.tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.reuseID, for: indexPath)
        let item = self.items[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = item.name
        content.textProperties.lineBreakMode = .byTruncatingTail
        content.textProperties.numberOfLines = 0

        switch item.type {
        case .recipe:
            cell.accessoryView = nil
            content.image = item.selected ? SFSymbols.checkmarkSquareFill : SFSymbols.square
            content.imageProperties.maximumSize = self.checkboxImageSize
            content.imageProperties.tintColor = item.selected ? StyleGuide.colors.primary : StyleGuide.colors.secondaryText
        case .folder:
            cell.accessoryView = self.accessoryImage(item.expanded ? SFSymbols.chevronDown : SFSymbols.chevronRight)
            content.image = SFSymbols.folder
            content.imageProperties.maximumSize = self.folderImageSize
            content.imageProperties.tintColor = StyleGuide.colors.primary
        }

        cell.contentConfiguration = content
        cell.indentationLevel = item.indent * 2
        cell.selectionStyle = .none

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = self.items[indexPath.row]
        switch item.type {
        case .recipe:
            self.toggleRecipe(at: indexPath)
        case .folder:
            if item.expanded {
                self.collapseFolder(at: indexPath)
            } else {
                self.expandFolder(at: indexPath)
            }
        }
    }

    private static func indexPathRange(start: Int, count: Int) -> [IndexPath] {
        return (start..<(start + count)).map { IndexPath(row: $0, section: 0) }
    }
}
