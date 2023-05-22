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

    func getItem(uuid: UUID) -> RecipeItem? {
        return self.items[uuid]
    }

    func getFolderItems(uuid: UUID) -> [RecipeItem]? {
        guard let item = self.getItem(uuid: uuid) else { return [] }

        switch item {
        case .recipe(_):
            return nil

        case .folder(let folder):
            var items: [RecipeItem] = []
            for itemId in folder.items {
                // if we somehow end up in a situation with a folder containing a non-existent
                // item, remove it
                if let item = self.getItem(uuid: itemId) {
                    items.append(item)
                } else  {
                    folder.removeItem(uuid: itemId)
                }
            }
            return items
        }
    }

    func addRecipe(recipe: Recipe) -> RBError? {
        let item = RecipeItem.recipe(recipe)
        self.items[recipe.uuid] = item

        // add to the parent folder
        let folderItem = self.getItem(uuid: recipe.folderId)!.intoFolder()!
        folderItem.addItem(uuid: recipe.uuid)

        return self.store()
    }

    func addFolder(folder: RecipeFolder) -> RBError? {
        let item = RecipeItem.folder(folder)
        self.items[folder.uuid] = item

        // add to the parent folder
        // unwrapping because we should never add more roots
        let folderItem = self.getItem(uuid: folder.folderId!)!.intoFolder()!
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
        let item = self.getItem(uuid: uuid)!

        // first unhook from the parent folder
        if let folderId = item.folderId {
            let folderItem = self.getItem(uuid: folderId)!.intoFolder()!
            folderItem.removeItem(uuid: uuid)
        } else {
            // folder ID should only be nil for the root, which should never be modified
            // this branch should never be hit...
            return .cannotModifyRoot
        }

        // then remove the item itself
        self.items.removeValue(forKey: uuid)

        return self.store()
    }

    func moveItemToFolder(uuid: UUID, folderId: UUID) -> RBError? {
        var item = self.getItem(uuid: uuid)!

        // first unhook from the parent folder
        if let parentFolderId = item.folderId {
            let folderItem = self.getItem(uuid: parentFolderId)!.intoFolder()!
            folderItem.removeItem(uuid: uuid)
        } else {
            // folder ID should only be nil for the root, which should never be modified
            // this branch should never be hit...
            return .cannotModifyRoot
        }

        // then add it to the new parent folder
        item.folderId = folderId
        let parentFolder = self.getItem(uuid: folderId)!.intoFolder()!
        parentFolder.addItem(uuid: item.uuid)

        return self.store()
    }
}
