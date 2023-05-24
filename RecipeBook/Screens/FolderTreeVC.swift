//
//  FolderTreeVC.swift
//  RecipeBook
//
//  Created by Ian Brault on 5/15/23.
//

import UIKit

class FolderTreeVC: UIViewController {
    static let reuseID = "FolderTreeCell"

    struct Item {
        let folder: RecipeFolder
        let indentLevel: Int
    }

    let tableView = UITableView()

    var items: [Item] = []
    var completionHander: ((RecipeFolder) -> Void)!

    init(completionHandler: @escaping (RecipeFolder) -> Void) {
        super.init(nibName: nil, bundle: nil)
        self.completionHander = completionHandler
        self.loadFolderTree()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func getFolderItems(folderId: UUID, indentLevel: Int) -> [Item] {
        let items = State.manager.getFolderItems(uuid: folderId)!
        let sortedFolders = items.filter { $0.isFolder }.sorted(by: RecipeItem.sortReverse).map { $0.intoFolder()! }
        return sortedFolders.map { Item(folder: $0, indentLevel: indentLevel) }
    }

    private func loadFolderTree() {
        // start with the root
        guard let root = State.manager.root else { return }
        let rootItem = State.manager.getItem(uuid: root)!.intoFolder()!
        self.items.append(Item(folder: rootItem, indentLevel: 0))

        var queue = self.getFolderItems(folderId: root, indentLevel: 1)
        while !queue.isEmpty {
            // create an item for the folder
            let item = queue.popLast()!
            self.items.append(item)
            // and then add sub-folders to the queue
            let subItems = self.getFolderItems(folderId: item.folder.uuid, indentLevel: item.indentLevel + 1)
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
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissVC))
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

        let cell = tableView.dequeueReusableCell(withIdentifier: FolderTreeVC.reuseID)!
        cell.indentationLevel = item.indentLevel * 2

        var content = cell.defaultContentConfiguration()
        content.attributedText = item.folder.attributedText()
        cell.contentConfiguration = content

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = self.items[indexPath.row]
        self.dismissVC()
        self.completionHander(item.folder)
    }
}
