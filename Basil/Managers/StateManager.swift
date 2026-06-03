//
//  StateManager.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/30/23.
//

import UIKit
import os

//
// Singleton class responsible for managing global application state
// Reflects state changes to persistence storage and to the remote server (if connected)
//
class StateManager {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: StateManager.self)
    )

    static let shared = StateManager()

    enum Item: Codable {
        case recipe
        case folder

        var name: String {
            switch self {
            case .recipe:
                return "recipe"
            case .folder:
                return "folder"
            }
        }
    }

    enum Action: Codable {
        case create(Item, ObjectID)
        case modify(Item, ObjectID)
        case delete(Item, ObjectID)
    }

    // Device identifier
    var device: UUID? = UIDevice.current.identifierForVendor

    // User information
    var tokenId: ObjectID? = nil
    var userId: ObjectID? = nil
    var userEmail: String = ""
    var userAuthenticated: Bool {
        return !self.userEmail.isEmpty && self.userId != nil
    }

    // ID of the root folder
    var root: ObjectID? = nil
    // Recipe/folder maps
    var recipes: [ObjectID: Recipe] = [:]
    var folders: [ObjectID: Folder] = [:]

    // Offline action queue
    static let offlineQueueSize = 1024
    var offlineQueue: RingBuffer<Action> = RingBuffer(
        size: StateManager.offlineQueueSize
    )

    // Grocery list
    var groceryList: GroceryList = GroceryList()

    // Set when communication with the server has been established
    var online: Bool = false

    // User has logged in/out so information might need to be reloaded
    var userChanged: Bool = false

    private init() {}

    func load() {
        self.userEmail = PersistenceManager.shared.email ?? ""

        if let root = PersistenceManager.shared.root {
            self.root = root
            self.recipes = PersistenceManager.shared.recipes
            self.folders = PersistenceManager.shared.folders
            self.offlineQueue = PersistenceManager.shared.offlineQueue
            Self.logger.notice(
                "Loaded root \(root) with \(self.recipes.count) recipes and \(self.folders.count) folders, \(self.offlineQueue.count) offline actions"
            )
        } else {
            // If the root does not exist, this is the first launch; create a new root
            self.createRoot()
        }

        self.groceryList = PersistenceManager.shared.groceryList
    }

    func storeRecipesAndFolders() {
        PersistenceManager.shared.root = self.root
        PersistenceManager.shared.recipes = self.recipes
        PersistenceManager.shared.folders = self.folders
        PersistenceManager.shared.offlineQueue = self.offlineQueue
    }

    func storeGroceryList() {
        PersistenceManager.shared.groceryList = self.groceryList
    }

    //
    // User
    //

    func clearUser() {
        self.tokenId = nil
        self.userId = nil
        self.userEmail.removeAll()
        self.root = nil
        self.recipes.removeAll()
        self.folders.removeAll()

        PersistenceManager.shared.email = nil

        do {
            try Keychain.deleteCredentials()
        } catch {}
    }

    func setUser(id: ObjectID, email: String, token: ObjectID) {
        self.userId = id
        self.userEmail = email
        self.tokenId = token

        PersistenceManager.shared.email = email
    }

    func authenticateUser(
        email: String,
        password: String,
        addToKeychain: Bool = true
    ) async throws {
        let info = try await API.authenticate(
            email: email,
            password: password
        )
        Self.logger.notice(
            "Successfully authenticated user \(email)"
        )
        // Clear out existing structures
        self.clearUser()
        // FIXME: should not be clearing the offline queue because this is called from the SceneDelegate
        // self.offlineQueue.removeAll()
        // Then populate with the authenticated user info
        self.setUser(id: info.id, email: info.email, token: info.token)
        self.root = info.root
        for recipeInfo in info.recipes {
            let recipe = Recipe(response: recipeInfo)
            self.recipes[recipe.uuid] = recipe
        }
        for folderInfo in info.folders {
            let folder = Folder(response: folderInfo)
            self.folders[folder.uuid] = folder
        }
        self.storeRecipesAndFolders()
        // Mark the user as online and signal to views that the user has changed
        self.online = true
        self.userChanged = true
        try Keychain.setCredentials(
            email: email,
            password: password
        )
    }

    func createUser(email: String, password: String) async throws {
        let info = try await API.createUser(
            root: self.root!,
            email: email,
            password: password
        )
        Self.logger.notice(
            "Successfully created user \(info.email)"
        )
        // Populate with the created user info
        self.setUser(id: info.id, email: info.email, token: info.token)
        // Process the offline action queue
        await self.processOfflineQueue()
        // Mark the user as online and signal to views that the user has changed
        self.online = true
        self.userChanged = true
        // Add the password to the keychain
        do {
            try Keychain.setCredentials(
                email: email,
                password: password
            )
        } catch let error {
            // Do not bail out here or all previous folders and recipes will be lost
            Self.logger.error("Error adding password to keychain: \(error)")
        }
    }

    func processOfflineQueue() async {
        let count = self.offlineQueue.count
        for action in self.offlineQueue {
            switch action {
            case .create(let item, let uuid):
                Self.logger.info(
                    "Processing offline action: create \(item.name) \(uuid)"
                )
                do {
                    switch item {
                    case .recipe:
                        let _ = try await API.createRecipe(self.recipes[uuid]!)
                    case .folder:
                        let _ = try await API.createFolder(self.folders[uuid]!)
                    }
                } catch {
                    break
                }
                break
            case .modify(let item, let uuid):
                Self.logger.info(
                    "Processing offline action: modify \(item.name) \(uuid)"
                )
                // FIXME: unimplemented
                break
            case .delete(let item, let uuid):
                Self.logger.info(
                    "Processing offline action: delete \(item.name) \(uuid)"
                )
                // FIXME: unimplemented
                break
            }
        }
        Self.logger.notice("Finished processing \(count) offline actions")
    }

    func removeUser() throws {
        // Clear out stored user info
        self.clearUser()
        // Clear the stored password from the keychain
        try Keychain.deleteCredentials()
        // Create a new root
        self.createRoot()
        // Mark the user as offline and signal to views that the user has changed
        self.online = false
        self.userChanged = true
    }

    func deleteUser(password: String) async throws {
        try await API.deleteUser(
            email: self.userEmail,
            password: password
        )
        try self.removeUser()
    }

    //
    // Recipes/Folders
    //

    func createRoot(uuid: ObjectID? = nil) {
        let rootFolder: Folder
        if let uuid {
            rootFolder = Folder(uuid: uuid, parent: nil, name: "")
        } else {
            rootFolder = Folder(parent: nil, name: "")
        }
        // Assert that a root does not already exist
        assert(
            self.root == nil,
            "Attempted to create a new root folder when one already exists"
        )
        self.root = rootFolder.uuid
        // Add to the folder list and map
        self.folders[rootFolder.uuid] = rootFolder
        Self.logger.info("Created root folder \(rootFolder.uuid)")
    }

    func addFolder(name: String, parent: ObjectID) async throws -> Folder {
        var folder = Folder(parent: parent, name: name)
        Self.logger.notice(
            "Creating folder \"\(name)\" (ID: \(folder.uuid)) with parent \(parent)"
        )

        // If the user is online, send the action to the server
        if self.online {
            do {
                let response = try await API.createFolder(folder)
                folder = Folder(response: response)
            } catch let error {
                Self.logger.error("Error creating folder: \(error)")
                // If the client/server has gone offline, enter offline mode and continue on
                if Network.isOfflineError(error) {
                    self.online = false
                } else {
                    throw error
                }
            }
        }

        // If the user is offline, store the action in the offline queue
        if !self.online {
            if self.offlineQueue.isFull {
                throw BasilError.offlineQueueFull
            }
            Self.logger.debug(
                "Adding offline action to create folder \(folder.uuid)"
            )
            self.offlineQueue.pushBack(.create(.folder, folder.uuid))
        }

        // Add the folder to the tracked state
        self.folders[folder.uuid] = folder
        // Then link to its parent
        guard let parentId = folder.parent, let parent = self.folders[parentId]
        else {
            Self.logger.error(
                "Missing parent \(folder.parent?.description ?? "nil") for folder \(folder.uuid)"
            )
            throw BasilError.missingFolder(folder.parent)
        }
        parent.addSubfolder(uuid: folder.uuid)
        self.storeRecipesAndFolders()
        return folder
    }

    func addRecipe(
        title: String,
        parent: ObjectID,
        ingredients: [String],
        instructions: [String]
    ) async throws -> Recipe {
        let ingredientStrings = ingredients.map {
            IngredientParser.shared.parse(string: $0)
        }
        var recipe = Recipe(
            parent: parent,
            title: title,
            ingredients: ingredientStrings,
            instructions: instructions
        )
        Self.logger.notice(
            "Creating recipe \"\(title)\" (ID: \(recipe.uuid)) with parent \(parent)"
        )

        // If the user is online, send the action to the server
        if self.online {
            do {
                let response = try await API.createRecipe(recipe)
                recipe = Recipe(response: response)
            } catch let error {
                Self.logger.error("Error creating recipe: \(error)")
                // If the client/server has gone offline, enter offline mode and continue on
                if Network.isOfflineError(error) {
                    self.online = false
                } else {
                    throw error
                }
            }
        }

        // If the user is offline, store the action in the offline queue
        if !self.online {
            if self.offlineQueue.isFull {
                throw BasilError.offlineQueueFull
            }
            Self.logger.debug(
                "Adding offline action to create recipe \(recipe.uuid)"
            )
            self.offlineQueue.pushBack(.create(.recipe, recipe.uuid))
        }

        // Add the recipe to the tracked state
        self.recipes[recipe.uuid] = recipe
        // Then link to its parent
        guard let parent = self.folders[recipe.parent]
        else {
            Self.logger.error(
                "Missing parent \(recipe.parent) for recipe \(recipe.uuid)"
            )
            throw BasilError.missingFolder(recipe.parent)
        }
        parent.addRecipe(uuid: recipe.uuid)
        self.storeRecipesAndFolders()
        return recipe
    }

    // FIXME: re-implement
    /*
    func updateRecipe(recipe updatedRecipe: Recipe) -> BasilError? {
        guard let recipe = self.getRecipe(uuid: updatedRecipe.uuid) else {
            return .missingItem(.recipe, updatedRecipe.uuid)
        }
        recipe.update(with: updatedRecipe)

        self.storeRecipesAndFolders()
        return nil
    }
    */

    // FIXME: re-implement
    /*
    func updateFolder(folder updatedFolder: Folder) -> BasilError? {
        guard let folder = self.getFolder(uuid: updatedFolder.uuid) else {
            return .missingItem(.folder, updatedFolder.uuid)
        }
        folder.update(with: updatedFolder)

        self.storeRecipesAndFolders()
        return nil
    }
    */

    // FIXME: re-implement
    /*
    func removeRecipe(recipe: Recipe) {
        // unhook from the parent folder
        if let parentFolder = self.getFolder(uuid: recipe.parent) {
            parentFolder.removeRecipe(uuid: recipe.uuid)
        }
        // then remove the recipe itself
        self.recipes.removeAll { $0.uuid == recipe.uuid }
        self.recipeMap.removeValue(forKey: recipe.uuid)
    }
    */

    // FIXME: re-implement
    /*
    func removeRecipe(uuid: UUID) {
        if let recipe = self.getRecipe(uuid: uuid) {
            self.removeRecipe(recipe: recipe)
        }
    }
    */

    // FIXME: re-implement
    /*
    func removeFolder(folder: Folder) {
        // guard removal of root
        guard let parentFolderId = folder.parent else { return }

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
    */

    // FIXME: re-implement
    /*
    func removeFolder(uuid: UUID) {
        if let folder = self.getFolder(uuid: uuid) {
            self.removeFolder(folder: folder)
        }
    }
    */

    // FIXME: re-implement
    /*
    func deleteItem(uuid: UUID) -> BasilError? {
        return self.deleteItems(uuids: [uuid])
    }
    */

    // FIXME: re-implement
    /*
    func deleteItems(uuids: [UUID]) -> BasilError? {
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

        self.storeRecipesAndFolders()
        return nil
    }
    */

    // FIXME: re-implement
    /*
    func moveRecipeToFolder(recipe: Recipe, folderId: UUID) -> BasilError? {
        // first unhook from the parent folder
        if let oldParentFolder = self.getFolder(uuid: recipe.parent) {
            oldParentFolder.removeRecipe(uuid: recipe.uuid)
        } else {
            return .missingItem(.folder, recipe.parent)
        }
        // then add it to the new parent folder
        recipe.parent = folderId
        if let newParentFolder = self.getFolder(uuid: folderId) {
            newParentFolder.addRecipe(uuid: recipe.uuid)
        } else {
            return .missingItem(.folder, folderId)
        }

        return nil
    }
    */

    // FIXME: re-implement
    /*
    func moveFolderToFolder(folder: Folder, folderId: UUID) -> BasilError? {
        // first unhook from the parent folder
        if let oldParentFolderId = folder.parent {
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
        folder.parent = folderId
        if let newParentFolder = self.getFolder(uuid: folderId) {
            newParentFolder.addSubfolder(uuid: folder.uuid)
        } else {
            return .missingItem(.folder, folderId)
        }

        return nil
    }
    */

    // FIXME: re-implement
    /*
    func moveItemToFolder(uuid: UUID, folderId: UUID) -> BasilError? {
        return self.moveItemsToFolder(uuids: [uuid], folderId: folderId)
    }
    */

    // FIXME: re-implement
    /*
    func moveItemsToFolder(uuids: [UUID], folderId: UUID) -> BasilError? {
        var recipes: [Recipe] = []
        var folders: [Folder] = []
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
                if !folderIds.contains(recipe.parent) {
                    if let parentFolder = self.getFolder(uuid: recipe.parent) {
                        folders.append(parentFolder)
                        folderIds.insert(recipe.parent)
                    } else {
                        error = .missingItem(.folder, recipe.parent)
                    }
                }
                // then move the recipe
                error = self.moveRecipeToFolder(
                    recipe: recipe,
                    folderId: folderId
                )
            } else if let folder = self.folderMap[uuid] {
                // track the folder so it can be updated via the API
                if !folderIds.contains(uuid) {
                    folders.append(folder)
                    folderIds.insert(uuid)
                }
                // also track the parent folder
                if let parentFolderId = folder.parent {
                    if !folderIds.contains(parentFolderId) {
                        if let parentFolder = self.getFolder(
                            uuid: parentFolderId
                        ) {
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
                error = self.moveFolderToFolder(
                    folder: folder,
                    folderId: folderId
                )
            } else {
                error = .missingItem(.recipe, uuid)
            }
            if let error {
                return error
            }
        }

        self.storeRecipesAndFolders()
        return nil
    }
    */

    func itemsMatchingText(_ text: String) -> [RecipeItem] {
        var items: [RecipeItem] = []

        for folder in self.folders.values {
            if folder.name.lowercased().contains(text.lowercased()) {
                items.append(.folder(folder))
            }
        }
        for recipe in self.recipes.values {
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

    func modifyGrocery(at indexPath: IndexPath, with grocery: Ingredient) {
        self.groceryList.modify(at: indexPath, with: grocery)
        self.storeGroceryList()
    }

    func replaceGrocery(at indexPath: IndexPath, with grocery: Ingredient)
        -> IndexPath
    {
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
}
