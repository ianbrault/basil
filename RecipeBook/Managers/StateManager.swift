//
//  StateManager.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/30/23.
//

import Foundation

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

    func load() -> RBError? {
        switch PersistenceManager.loadState() {
        case .success(let data):
            self.userId = data.userId
            self.userKey = data.userKey
            self.root = data.root
            self.loadRecipes(recipes: data.recipes)
            self.loadFolders(folders: data.folders)
            return nil

        case .failure(let error):
            return error
        }
    }

    func store() -> RBError? {
        let data = Data(
            userId: self.userId,
            userKey: self.userKey,
            root: self.root,
            recipes: self.recipes,
            folders: self.folders
        )
        return PersistenceManager.storeState(state: data)
    }

    func addUserInfo(info: UserLoginResponse) -> RBError? {
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

        return self.store()
    }

    func getRecipe(uuid: UUID) -> Recipe? {
        return self.recipeMap[uuid]
    }

    func getFolder(uuid: UUID) -> RecipeFolder? {
        return self.folderMap[uuid]
    }

    func addRecipe(recipe: Recipe, push: Bool = true, store: Bool = true) -> RBError? {
        var error: RBError? = nil

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

        if push {
            API.createItem(recipe: recipe)
        }
        if store {
            error = self.store()
        }
        return error
    }

    func addFolder(folder: RecipeFolder, push: Bool = true, store: Bool = true) -> RBError? {
        var error: RBError? = nil

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

        if push {
            API.createItem(folder: folder)
        }
        if store {
            error = self.store()
        }
        return error
    }

    func updateRecipe(recipe updatedRecipe: Recipe) -> RBError? {
        guard let recipe = self.getRecipe(uuid: updatedRecipe.uuid) else {
            return .missingItem(.recipe, updatedRecipe.uuid)
        }
        recipe.update(with: updatedRecipe)
        API.updateItems(recipes: [recipe])
        return self.store()
    }

    func updateFolder(folder updatedFolder: RecipeFolder) -> RBError? {
        guard let folder = self.getFolder(uuid: updatedFolder.uuid) else {
            return .missingItem(.folder, updatedFolder.uuid)
        }
        folder.update(with: updatedFolder)
        API.updateItems(folders: [folder])
        return self.store()
    }

    func deleteRecipe(recipe: Recipe, andStore: Bool = true) -> RBError? {
        // unhook from the parent folder
        if let parentFolder = self.getFolder(uuid: recipe.folderId) {
            parentFolder.removeRecipe(uuid: recipe.uuid)
        } else {
            return .missingItem(.folder, recipe.folderId)
        }
        // then remove the recipe itself
        self.recipes.removeAll { $0.uuid == recipe.uuid }
        self.recipeMap.removeValue(forKey: recipe.uuid)

        return andStore ? self.store() : nil
    }

    func deleteFolder(folder: RecipeFolder, andStore: Bool = true) -> RBError? {
        // first recursively delete sub-items
        if let error = self.deleteItems(uuids: folder.subfolders) ?? self.deleteItems(uuids: folder.recipes) {
            return error
        }

        // unhook from the parent folder
        if let parentFolderId = folder.folderId {
            if let parentFolder = self.getFolder(uuid: parentFolderId) {
                parentFolder.removeSubfolder(uuid: folder.uuid)
            } else {
                return .missingItem(.folder, parentFolderId)
            }
        } else {
            // this branch should never be hit
            // folder ID should only be nil for the root, which should never be modified
            return .cannotModifyRoot
        }
        // then remove the folder itself
        self.folders.removeAll { $0.uuid == folder.uuid }
        self.folderMap.removeValue(forKey: folder.uuid)

        return andStore ? self.store() : nil
    }

    func deleteItem(uuid: UUID) -> RBError? {
        return self.deleteItems(uuids: [uuid])
    }

    func deleteItems(uuids: [UUID]) -> RBError? {
        for uuid in uuids {
            var error: RBError? = nil
            if let recipe = self.recipeMap[uuid] {
                error = self.deleteRecipe(recipe: recipe, andStore: false)
            } else if let folder = self.folderMap[uuid] {
                error = self.deleteFolder(folder: folder, andStore: false)
            } else {
                error = .missingItem(.recipe, uuid)
            }
            if let error {
                return error
            }
        }

        return self.store()
    }

    func moveRecipeToFolder(recipe: Recipe, folderId: UUID, andStore: Bool = true) -> RBError? {
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

        return andStore ? self.store() : nil
    }

    func moveFolderToFolder(folder: RecipeFolder, folderId: UUID, andStore: Bool = true) -> RBError? {
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

        return andStore ? self.store() : nil
    }

    func moveItemToFolder(uuid: UUID, folderId: UUID) -> RBError? {
        return self.moveItemsToFolder(uuids: [uuid], folderId: folderId)
    }

    func moveItemsToFolder(uuids: [UUID], folderId: UUID) -> RBError? {
        for uuid in uuids {
            var error: RBError? = nil
            if let recipe = self.recipeMap[uuid] {
                error = self.moveRecipeToFolder(recipe: recipe, folderId: folderId, andStore: false)
            } else if let folder = self.folderMap[uuid] {
                error = self.moveFolderToFolder(folder: folder, folderId: folderId, andStore: false)
            } else {
                error = .missingItem(.recipe, uuid)
            }
            if let error {
                return error
            }
        }

        return self.store()
    }

    func clear() {
        // NOTE: this should only be used for development debugging
        self.userId = ""
        self.userKey = nil

        let root = RecipeFolder.root()
        self.root = root.uuid
        self.folders = [root]
        self.folderMap = [root.uuid: root]
        self.recipes = []
        self.recipeMap = [:]

        let _ = self.store()
    }
}
