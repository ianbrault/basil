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
        let userId: String
        let root: UUID?
        let items: [UUID: RecipeItem]

        static func empty() -> Data {
            // create the root folder
            let rootFolder = RecipeFolder.root()
            let items = [rootFolder.uuid: RecipeItem.folder(rootFolder)]
            return Data(userId: "", root: rootFolder.uuid, items: items)
        }
    }

    static let manager = State()

    // user ID and key
    var userId: String = ""
    var userKey: UUID?
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
        let data = Data(userId: self.userId, root: self.root, items: self.items)
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

    func addUserInfo(id: String, key: UUID) -> RBError? {
        self.userId = id
        self.userKey = key

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
        return self.deleteItems(uuids: [uuid])
    }

    func deleteItems(uuids: [UUID]) -> RBError? {
        for uuid in uuids {
            let item = self.getItem(uuid: uuid)!
            // if this is a folder, first recursively delete its sub-items
            if item.isFolder {
                if let error = self.deleteItems(uuids: item.intoFolder()!.items) {
                    return error
                }
            }

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
        }

        return self.store()
    }

    func moveItemToFolder(uuid: UUID, folderId: UUID) -> RBError? {
        return self.moveItemsToFolder(uuids: [uuid], folderId: folderId)
    }

    func moveItemsToFolder(uuids: [UUID], folderId: UUID) -> RBError? {
        for uuid in uuids {
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
        }

        return self.store()
    }

    func clear() {
        // NOTE: this should only be used for development debugging
        self.userId = ""
        self.userKey = nil
        let root = self.getItem(uuid: self.root!)!
        let _ = self.deleteItems(uuids: root.intoFolder()!.items)
    }
}
