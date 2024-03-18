//
//  StateManager.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/30/23.
//

import UIKit

class State {

    enum Item {
        case recipe
        case folder
    }

    // use a separate data type for encoding/decoding
    struct Data: Codable {
        let userId: String
        let userKey: UUID?
        let root: UUID?
        let recipes: [Recipe]
        let folders: [RecipeFolder]

        static func empty() -> Data {
            return Data(userId: "", userKey: nil, root: nil, recipes: [], folders: [])
        }
    }

    static let manager = State()

    // window used to present error alerts
    var window: UIWindow?

    // user ID and key
    var userId: String = ""
    var userKey: UUID? = nil

    // ID of the root folder
    var root: UUID? = nil
    // recipe/folder lists
    var recipes: [Recipe] = []
    var folders: [RecipeFolder] = []
    // maps IDs to recipes/folders
    // managed volatilely, not put in storage
    var recipeMap: [UUID: Recipe] = [:]
    var folderMap: [UUID: RecipeFolder] = [:]

    // grocery list
    var groceries: [Grocery] = []

    // has communication with the server been established?
    var serverCommunicationEstablished: Bool = false
    // prevent unnecessary pokes if we were not able to establish server communication
    var serverPoked: Bool = false

    private init() {}

    private func loadRecipes(recipes: [Recipe]) {
        self.recipes = recipes
        for recipe in self.recipes {
            self.recipeMap[recipe.uuid] = recipe
        }
    }

    private func loadFolders(folders: [RecipeFolder]) {
        self.folders = folders
        for folder in self.folders {
            self.folderMap[folder.uuid] = folder
        }
    }

    func load() {
        let data = PersistenceManager.shared.state
        self.userId = data.userId
        self.userKey = data.userKey
        self.root = data.root
        self.loadRecipes(recipes: data.recipes)
        self.loadFolders(folders: data.folders)
        self.groceries = PersistenceManager.shared.groceries
    }

    func storeToLocal() {
        let data = Data(
            userId: self.userId,
            userKey: self.userKey,
            root: self.root,
            recipes: self.recipes,
            folders: self.folders
        )
        PersistenceManager.shared.state = data
    }

    func store() {
        PersistenceManager.shared.needsToUpdateServer = true
        // first store to persistence storage
        self.storeToLocal()
        // then push to the server asynchronously
        if self.serverCommunicationEstablished {
            API.updateUser(async: true) { (error) in
                if let error {
                    // present an alert on the main window and disable further communication with the server
                    self.window?.rootViewController?.presentErrorAlert(error)
                    self.serverCommunicationEstablished = false
                } else {
                    PersistenceManager.shared.needsToUpdateServer = false
                }
            }
        }
    }

    func addUserInfo(info: API.UserInfo) {
        self.userId = info.id
        self.userKey = info.key
        self.root = info.root
        for recipe in info.recipes {
            self.recipes.append(recipe)
            self.recipeMap[recipe.uuid] = recipe
        }
        for folder in info.folders {
            self.folders.append(folder)
            self.folderMap[folder.uuid] = folder
        }

        self.storeToLocal()
    }

    func getRecipe(uuid: UUID) -> Recipe? {
        return self.recipeMap[uuid]
    }

    func getFolder(uuid: UUID) -> RecipeFolder? {
        return self.folderMap[uuid]
    }

    func addRecipe(recipe: Recipe) -> RBError? {
        // add the recipe to the stored recipe list
        self.recipes.append(recipe)
        // and to the volatile recipe map
        self.recipeMap[recipe.uuid] = recipe
        // and then add it to the parent folder
        if let folder = self.getFolder(uuid: recipe.folderId) {
            folder.addRecipe(uuid: recipe.uuid)
        } else {
            return .missingItem(.folder, recipe.folderId)
        }

        self.store()
        return nil
    }

    func addFolder(folder: RecipeFolder) -> RBError? {
        // add the folder to the stored folder list
        self.folders.append(folder)
        // and to the volatile folder map
        self.folderMap[folder.uuid] = folder
        // and then add it to the parent folder
        if let parentId = folder.folderId {
            if let parentFolder = self.getFolder(uuid: parentId) {
                parentFolder.addSubfolder(uuid: folder.uuid)
            } else {
                return .missingItem(.folder, parentId)
            }
        }

        self.store()
        return nil
    }

    func updateRecipe(recipe updatedRecipe: Recipe) -> RBError? {
        guard let recipe = self.getRecipe(uuid: updatedRecipe.uuid) else {
            return .missingItem(.recipe, updatedRecipe.uuid)
        }
        recipe.update(with: updatedRecipe)

        self.store()
        return nil
    }

    func updateFolder(folder updatedFolder: RecipeFolder) -> RBError? {
        guard let folder = self.getFolder(uuid: updatedFolder.uuid) else {
            return .missingItem(.folder, updatedFolder.uuid)
        }
        folder.update(with: updatedFolder)

        self.store()
        return nil
    }

    func removeRecipe(recipe: Recipe) {
        // unhook from the parent folder
        if let parentFolder = self.getFolder(uuid: recipe.folderId) {
            parentFolder.removeRecipe(uuid: recipe.uuid)
        }
        // then remove the recipe itself
        self.recipes.removeAll { $0.uuid == recipe.uuid }
        self.recipeMap.removeValue(forKey: recipe.uuid)
    }

    func removeRecipe(uuid: UUID) {
        if let recipe = self.getRecipe(uuid: uuid) {
            self.removeRecipe(recipe: recipe)
        }
    }

    func removeFolder(folder: RecipeFolder) {
        // guard removal of root
        guard let parentFolderId = folder.folderId else { return }

        // first recursively delete sub-items
        for uuid in folder.subfolders {
            self.removeFolder(uuid: uuid)
        }
        for uuid in folder.recipes {
            self.removeRecipe(uuid: uuid)
        }

        // unhook from the parent folder
        if let parentFolder = self.getFolder(uuid: parentFolderId) {
            parentFolder.removeSubfolder(uuid: folder.uuid)
        }
        // then remove the folder itself
        self.folders.removeAll { $0.uuid == folder.uuid }
        self.folderMap.removeValue(forKey: folder.uuid)
    }

    func removeFolder(uuid: UUID) {
        if let folder = self.getFolder(uuid: uuid) {
            self.removeFolder(folder: folder)
        }
    }

    func deleteItem(uuid: UUID) -> RBError? {
        return self.deleteItems(uuids: [uuid])
    }

    func deleteItems(uuids: [UUID]) -> RBError? {
        var recipes: [UUID] = []
        var folders: [UUID] = []
        for uuid in uuids {
            if let recipe = self.recipeMap[uuid] {
                recipes.append(uuid)
                self.removeRecipe(recipe: recipe)
            } else if let folder = self.folderMap[uuid] {
                folders.append(uuid)
                self.removeFolder(folder: folder)
            } else {
                return .missingItem(.recipe, uuid)
            }
        }

        self.store()
        return nil
    }

    func moveRecipeToFolder(recipe: Recipe, folderId: UUID) -> RBError? {
        // first unhook from the parent folder
        if let oldParentFolder = self.getFolder(uuid: recipe.folderId) {
            oldParentFolder.removeRecipe(uuid: recipe.uuid)
        } else {
            return .missingItem(.folder, recipe.folderId)
        }
        // then add it to the new parent folder
        recipe.folderId = folderId
        if let newParentFolder = self.getFolder(uuid: folderId) {
            newParentFolder.addRecipe(uuid: recipe.uuid)
        } else {
            return .missingItem(.folder, folderId)
        }

        return nil
    }

    func moveFolderToFolder(folder: RecipeFolder, folderId: UUID) -> RBError? {
        // first unhook from the parent folder
        if let oldParentFolderId = folder.folderId {
            if let oldParentFolder = self.getFolder(uuid: oldParentFolderId) {
                oldParentFolder.removeSubfolder(uuid: folder.uuid)
            } else {
                return .missingItem(.folder, oldParentFolderId)
            }
        } else {
            // this branch should never be hit
            // folder ID should only be nil for the root, which should never be modified
            return .cannotModifyRoot
        }
        // then add it to the new parent folder
        folder.folderId = folderId
        if let newParentFolder = self.getFolder(uuid: folderId) {
            newParentFolder.addSubfolder(uuid: folder.uuid)
        } else {
            return .missingItem(.folder, folderId)
        }

        return nil
    }

    func moveItemToFolder(uuid: UUID, folderId: UUID) -> RBError? {
        return self.moveItemsToFolder(uuids: [uuid], folderId: folderId)
    }

    func moveItemsToFolder(uuids: [UUID], folderId: UUID) -> RBError? {
        var recipes: [Recipe] = []
        var folders: [RecipeFolder] = []
        var recipeIds: Set<UUID> = []
        var folderIds: Set<UUID> = []

        if let folder = self.getFolder(uuid: folderId) {
            folders.append(folder)
            folderIds.insert(folderId)
        } else {
            return .missingItem(.folder, folderId)
        }

        for uuid in uuids {
            var error: RBError? = nil
            if let recipe = self.recipeMap[uuid] {
                // track the recipe so it can be updated via the API
                if !recipeIds.contains(uuid) {
                    recipes.append(recipe)
                    recipeIds.insert(uuid)
                }
                // also track the parent folder
                if !folderIds.contains(recipe.folderId) {
                    if let parentFolder = self.getFolder(uuid: recipe.folderId) {
                        folders.append(parentFolder)
                        folderIds.insert(recipe.folderId)
                    } else {
                        error = .missingItem(.folder, recipe.folderId)
                    }
                }
                // then move the recipe
                error = self.moveRecipeToFolder(recipe: recipe, folderId: folderId)
            } else if let folder = self.folderMap[uuid] {
                // track the folder so it can be updated via the API
                if !folderIds.contains(uuid) {
                    folders.append(folder)
                    folderIds.insert(uuid)
                }
                // also track the parent folder
                if let parentFolderId = folder.folderId {
                    if !folderIds.contains(parentFolderId) {
                        if let parentFolder = self.getFolder(uuid: parentFolderId) {
                            folders.append(parentFolder)
                            folderIds.insert(parentFolderId)
                        } else {
                            error = .missingItem(.folder, parentFolderId)
                        }
                    }
                } else {
                    error = .cannotModifyRoot
                }
                // then move the folder
                error = self.moveFolderToFolder(folder: folder, folderId: folderId)
            } else {
                error = .missingItem(.recipe, uuid)
            }
            if let error {
                return error
            }
        }

        self.store()
        return nil
    }

    func updateGroceries(groceries: [Grocery]) {
        self.groceries = groceries
        PersistenceManager.shared.groceries = groceries
    }

    func clear() {
        // NOTE: this should only be used for development debugging
        guard let rootId = self.root else { return }
        guard let root = self.getFolder(uuid: rootId) else { return }
        self.groceries = []
        let _ = self.deleteItems(uuids: root.subfolders + root.recipes)
    }
}
