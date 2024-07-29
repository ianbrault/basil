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
class FolderTreeVC: UIViewController {
    static let reuseID = "FolderTreeCell"

    struct Item {
        let folder: RecipeFolder
        let indentLevel: Int
    }

    let tableView = UITableView()

    var items: [Item] = []
    var currentFolder: UUID!
    var completionHander: ((RecipeFolder) -> Void)!

    init(currentFolder: UUID, completionHandler: @escaping (RecipeFolder) -> Void) {
        super.init(nibName: nil, bundle: nil)
        self.currentFolder = currentFolder
        self.completionHander = completionHandler
        self.loadFolderTree()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func getFolderItems(folder: RecipeFolder, indentLevel: Int) -> [Item] {
        let subfolders = folder.subfolders.map { State.manager.getFolder(uuid: $0)! }
        let sortedFolders = subfolders.sorted(by: RecipeFolder.sortReverse)
        return sortedFolders.map { Item(folder: $0, indentLevel: indentLevel) }
    }

    private func loadFolderTree() {
        // start with the root
        let root = State.manager.root!
        let rootFolder = State.manager.getFolder(uuid: root)!
        self.items.append(Item(folder: rootFolder, indentLevel: 0))

        var queue = self.getFolderItems(folder: rootFolder, indentLevel: 1)
        while !queue.isEmpty {
            // create an item for the folder
            let item = queue.popLast()!
            self.items.append(item)
            // and then add sub-folders to the queue
            let subItems = self.getFolderItems(folder: item.folder, indentLevel: item.indentLevel + 1)
            queue.append(contentsOf: subItems)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureViewController()
        self.configureTableView()
    }

    private func configureViewController() {
        self.title = "Move to folder"

        // dismiss the view when the cancel button is tapped
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.dismissVC))
        self.navigationItem.rightBarButtonItem = cancelButton
    }

    private func configureTableView() {
        self.view.addSubview(self.tableView)

        self.tableView.frame = self.view.bounds
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.removeExcessCells()

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: FolderTreeVC.reuseID)
    }

    @objc func dismissVC() {
        self.dismiss(animated: true)
    }
}

extension FolderTreeVC: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.items[indexPath.row]
        let isEnabled = item.folder.uuid != self.currentFolder

        let cell = tableView.dequeueReusableCell(withIdentifier: FolderTreeVC.reuseID)!
        cell.indentationLevel = item.indentLevel * 2

        var content = cell.defaultContentConfiguration()
        content.attributedText = item.folder.attributedText(namePlaceholder: "Recipes", isEnabled: isEnabled)
        cell.contentConfiguration = content
        cell.isUserInteractionEnabled = isEnabled

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = self.items[indexPath.row]
        self.dismissVC()
        self.completionHander(item.folder)
    }
}
