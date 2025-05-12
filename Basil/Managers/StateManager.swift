//
//  StateManager.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/30/23.
//

import UIKit

//
// Singleton class responsible for managing global application state
// Reflects state changes to persistence storage and to the remote server (if connected)
//
class State {

    enum Item {
        case recipe
        case folder
    }

    // use a separate data type for encoding/decoding
    struct Storage: Codable {
        let userId: String
        let userEmail: String
        let root: UUID?
        let recipes: [Recipe]
        let folders: [RecipeFolder]

        static func empty() -> Storage {
            return Storage(userId: "", userEmail: "", root: nil, recipes: [], folders: [])
        }
    }

    static let manager = State()

    // device token, used for notifications
    var deviceToken: UUID? = nil

    // user information
    var userId: String = ""
    var userEmail: String = ""

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
    var groceryList: GroceryList = GroceryList()

    // read-only mode
    // toggled when a user is logged in but a connection cannot be made to the server
    var readOnly: Bool = false
    // a user has logged in or out so information might need to be reloaded
    var userChanged: Bool = false

    private init() {}

    //
    // Local/Remote storage
    //

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
        self.deviceToken = UIDevice.current.identifierForVendor

        let data = PersistenceManager.shared.state
        self.userId = data.userId
        self.userEmail = data.userEmail
        // create a root folder if it does not already exist
        // this should be the case on the first launch
        if let root = data.root {
            self.root = root
            self.loadRecipes(recipes: data.recipes)
            self.loadFolders(folders: data.folders)
        } else {
            let root = RecipeFolder(folderId: nil, name: "")
            self.root = root.uuid
            self.loadRecipes(recipes: [])
            self.loadFolders(folders: [root])
        }

        self.groceryList = PersistenceManager.shared.groceryList
    }

    func storeToLocal() {
        let data = Storage(
            userId: self.userId,
            userEmail: self.userEmail,
            root: self.root,
            recipes: self.recipes,
            folders: self.folders
        )
        PersistenceManager.shared.state = data
    }

    func storeToServer() {
        // only store to the server if the user is logged into an account
        guard !self.userId.isEmpty else { return }
        assertionFailure()
        /*
        API.updateUser(async: true) { (error) in
            if let error {
                // present an alert on the main window and disable further communication with the server
                UIApplication.shared.windowRootViewController?.presentErrorAlert(error)
            }
        }
        */
    }

    func storeGroceryList() {
        PersistenceManager.shared.groceryList = self.groceryList
    }

    func store() {
        // first store to persistence storage
        self.storeToLocal()
        // then push to the server asynchronously
        self.storeToServer()
    }

    //
    // User
    //

    func addUserInfo(info: API.UserInfo) {
        self.userId = info.id
        self.userEmail = info.email
        self.root = info.root

        // clear out existing structures
        self.recipes.removeAll()
        self.folders.removeAll()
        self.recipeMap.removeAll()
        self.folderMap.removeAll()
        // then load recipes/folders from user info
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

    func clearUserInfo() {
        self.userId = ""
        self.userEmail = ""
        self.root = nil
        self.recipes.removeAll()
        self.folders.removeAll()
        self.recipeMap.removeAll()
        self.folderMap.removeAll()

        // create a new root
        let root = RecipeFolder(folderId: nil, name: "")
        self.root = root.uuid
        self.loadRecipes(recipes: [])
        self.loadFolders(folders: [root])

        self.storeToLocal()
    }

    //
    // Recipes/Folders
    //

    func getRecipe(uuid: UUID) -> Recipe? {
        return self.recipeMap[uuid]
    }

    func getFolder(uuid: UUID) -> RecipeFolder? {
        return self.folderMap[uuid]
    }

    func addRecipe(recipe: Recipe) -> BasilError? {
        guard !self.readOnly else { return .readOnly("add", .recipe) }

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

    func addFolder(folder: RecipeFolder) -> BasilError? {
        guard !self.readOnly else { return .readOnly("add", .folder) }

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

    func updateRecipe(recipe updatedRecipe: Recipe) -> BasilError? {
        guard !self.readOnly else { return .readOnly("modify", .recipe) }

        guard let recipe = self.getRecipe(uuid: updatedRecipe.uuid) else {
            return .missingItem(.recipe, updatedRecipe.uuid)
        }
        recipe.update(with: updatedRecipe)

        self.store()
        return nil
    }

    func updateFolder(folder updatedFolder: RecipeFolder) -> BasilError? {
        guard !self.readOnly else { return .readOnly("modify", .folder) }

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

    func deleteItem(uuid: UUID) -> BasilError? {
        guard !self.readOnly else { return .readOnly("delete", .recipe) }

        return self.deleteItems(uuids: [uuid])
    }

    func deleteItems(uuids: [UUID]) -> BasilError? {
        guard !self.readOnly else { return .readOnly("delete", .recipe) }

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

    func moveRecipeToFolder(recipe: Recipe, folderId: UUID) -> BasilError? {
        guard !self.readOnly else { return .readOnly("move", .recipe) }

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

    func moveFolderToFolder(folder: RecipeFolder, folderId: UUID) -> BasilError? {
        guard !self.readOnly else { return .readOnly("move", .folder) }

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

    func moveItemToFolder(uuid: UUID, folderId: UUID) -> BasilError? {
        guard !self.readOnly else { return .readOnly("move", .recipe) }
        return self.moveItemsToFolder(uuids: [uuid], folderId: folderId)
    }

    func moveItemsToFolder(uuids: [UUID], folderId: UUID) -> BasilError? {
        guard !self.readOnly else { return .readOnly("move", .recipe) }

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
            var error: BasilError? = nil
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

    func itemsMatchingText(_ text: String) -> [RecipeItem] {
        var items: [RecipeItem] = []

        for folder in self.folders {
            if folder.name.lowercased().contains(text.lowercased()) {
                items.append(.folder(folder))
            }
        }
        for recipe in self.recipes {
            if recipe.title.lowercased().contains(text.lowercased()) {
                items.append(.recipe(recipe))
            }
        }

        return items
    }

    //
    // Grocery List
    //

    func addToGroceryList(_ ingredient: Ingredient) {
        self.groceryList.addIngredient(ingredient)
        self.storeGroceryList()
    }

    func addToGroceryList(from recipe: Recipe) {
        self.groceryList.addIngredients(from: recipe)
        self.storeGroceryList()
    }

    func replaceGrocery(at indexPath: IndexPath, with grocery: Ingredient) -> IndexPath {
        let indexPath = self.groceryList.replace(at: indexPath, with: grocery)
        self.storeGroceryList()
        return indexPath
    }

    func removeGrocery(at indexPath: IndexPath) {
        self.groceryList.remove(at: indexPath)
        self.storeGroceryList()
    }

    func removeAllGroceries() {
        self.groceryList.clear()
        self.storeGroceryList()
    }

    //
    // Debug functions
    //

    func dump() -> String {
        let data = Storage(
            userId: self.userId,
            userEmail: self.userEmail,
            root: self.root,
            recipes: self.recipes,
            folders: self.folders
        )
        let encoded = try? JSONEncoder().encode(data)
        return encoded?.prettyPrintedJSONString ?? ""
    }

    func clear() {
        // NOTE: this should only be used for development debugging
        self.userId = ""
        self.userEmail = ""
        self.root = nil
        self.recipes.removeAll()
        self.folders.removeAll()
        self.recipeMap.removeAll()
        self.folderMap.removeAll()
        self.storeToLocal()
    }
}
