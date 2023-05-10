//
//  StateManager.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/30/23.
//

import Foundation

class State {
    // use a separate data type for encoding/decoding
    struct Data: Codable {
        let root: UUID?
        let items: [UUID: RecipeItem]

        static func empty() -> Data {
            // create the root folder
            let rootFolder = RecipeFolder.root()
            let items = [rootFolder.uuid: RecipeItem.folder(rootFolder)]
            return Data(root: rootFolder.uuid, items: items)
        }
    }

    static let manager = State()

    // ID of the root folder
    var root: UUID? = nil
    // maps IDs to items (recipes/folders)
    var items: [UUID: RecipeItem] = [:]

    private init() {}

    func load() -> RBError? {
        switch PersistenceManager.loadState() {
        case .success(let data):
            self.root = data.root
            self.items = data.items
            return nil

        case .failure(let error):
            return error
        }
    }

    func store() -> RBError? {
        let data = Data(root: self.root, items: self.items)
        return PersistenceManager.storeState(state: data)
    }

    func getItem(uuid: UUID) -> RecipeItem {
        return self.items[uuid]!
    }

    func getFolderItems(uuid: UUID) -> [RecipeItem]? {
        switch self.getItem(uuid: uuid) {
        case .recipe(_):
            return nil

        case .folder(let folder):
            return folder.items.map { self.getItem(uuid: $0) }
        }
    }

    func addRecipe(recipe: Recipe) -> RBError? {
        let item = RecipeItem.recipe(recipe)
        self.items[recipe.uuid] = item

        // add to the parent folder
        let folderItem = self.getItem(uuid: recipe.folderId).intoFolder()!
        folderItem.addItem(uuid: recipe.uuid)

        return self.store()
    }

    func addFolder(folder: RecipeFolder) -> RBError? {
        let item = RecipeItem.folder(folder)
        self.items[folder.uuid] = item

        // add to the parent folder
        // unwrapping because we should never add more roots
        let folderItem = self.getItem(uuid: folder.folderId!).intoFolder()!
        folderItem.addItem(uuid: folder.uuid)

        return self.store()
    }

    func updateRecipe(recipe: Recipe) -> RBError? {
        let item = RecipeItem.recipe(recipe)
        self.items[recipe.uuid] = item

        return self.store()
    }

    func updateFolder(folder: RecipeFolder) -> RBError? {
        let item = RecipeItem.folder(folder)
        self.items[folder.uuid] = item

        return self.store()
    }

    func deleteItem(uuid: UUID) -> RBError? {
        let item = self.getItem(uuid: uuid)

        // first unhook from the parent folder
        if let folderId = item.folderId {
            let folderItem = self.getItem(uuid: folderId).intoFolder()!
            folderItem.removeItem(uuid: uuid)
        } else {
            // folder ID should only be nil for the root, which should never be deleted
            // this branch should never be hit...
            return .cannotDeleteRoot
        }

        // then remove the item itself
        self.items.removeValue(forKey: uuid)

        return self.store()
    }
}
