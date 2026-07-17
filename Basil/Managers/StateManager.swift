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
final class StateManager {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: StateManager.self)
    )

    enum CodingKeys: String, CodingKey {
        case userEmail
        case root
        case recipes
        case folders
        case offlineQueue
        case groceryList
    }

    enum Action: Codable {
        case create(ObjectID)
        case modify(ObjectID)
        case delete(ObjectID)
    }

    static let shared =
        Storage.getObject(forKey: Storage.Key.state) ?? StateManager()

    // Device identifier
    var device: UUID? = UIDevice.current.identifierForVendor

    // User information
    var tokenId: ObjectID? = nil
    var userId: ObjectID? = nil
    var userEmail: String
    var userAuthenticated: Bool {
        return !self.userEmail.isEmpty && self.userId != nil
    }

    // ID of the root folder
    var root: ObjectID?
    // Recipe/folder maps
    var recipes: [ObjectID: Recipe]
    var folders: [ObjectID: Folder]

    // Offline action queue
    static let offlineQueueSize = 1024
    var offlineQueue: RingBuffer<Action>

    // Grocery list
    var groceryList: GroceryList

    // Set when communication with the server has been established
    var online: Bool = false

    // User has logged in/out so information might need to be reloaded
    var userChanged: Bool = false

    private init(
        userEmail: String = "",
        root: ObjectID? = nil,
        recipes: [Recipe] = [],
        folders: [Folder] = [],
        offlineQueue: RingBuffer<Action> = RingBuffer(
            size: StateManager.offlineQueueSize
        ),
        groceryList: GroceryList = GroceryList()
    ) {
        self.userEmail = userEmail
        self.recipes = [:]
        self.folders = [:]
        self.offlineQueue = offlineQueue
        self.groceryList = groceryList

        if let root {
            self.root = root
            for recipe in recipes {
                self.recipes[recipe.uuid] = recipe
            }
            for folder in folders {
                self.folders[folder.uuid] = folder
            }
            Self.logger.notice(
                "Loaded root \(root) with \(recipes.count) recipes and \(folders.count) folders and \(offlineQueue.count) offline actions"
            )
        } else {
            // If the root does not exist, this is the first launch; create a new root
            self.offlineQueue.removeAll()
            self.createRoot()
        }
    }

    func store() {
        Storage.setObject(self, forKey: Storage.Key.state)
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
        self.store()
        do {
            try Keychain.deleteCredentials()
        } catch {}
    }

    func setUser(id: ObjectID, email: String, token: ObjectID) {
        self.userId = id
        self.userEmail = email
        self.tokenId = token
    }

    func authenticateUser(
        email: String,
        password: String,
        clearUser: Bool = false,
        clearOfflineQueue: Bool = false,
        addToKeychain: Bool = true,
    ) async throws {
        let info = try await API.authenticate(
            email: email,
            password: password
        )
        Self.logger.notice(
            "Successfully authenticated user \(email)"
        )
        if clearUser {
            // Clear out existing structures
            self.clearUser()
        }
        if clearOfflineQueue {
            self.offlineQueue.removeAll()
        }
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
        self.store()
        // Process the offline action queue
        await self.processOfflineQueue()
        // Mark the user as online and signal to views that the user has changed
        self.online = true
        self.userChanged = true
        if addToKeychain {
            try Keychain.setCredentials(
                email: email,
                password: password
            )
        }
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
        self.store()
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
            Self.logger.info("Processing offline action: \(action)")
            switch action {
            case .create(let uuid):
                do {
                    if let recipe = self.recipes[uuid] {
                        let _ = try await API.createRecipe(recipe)
                    } else if let folder = self.folders[uuid] {
                        let _ = try await API.createFolder(folder)
                    }
                } catch {
                    break
                }
                break
            case .modify(let uuid):
                do {
                    if let recipe = self.recipes[uuid] {
                        let _ = try await API.updateRecipe(recipe)
                    } else if let folder = self.folders[uuid] {
                        let _ = try await API.updateFolder(folder)
                    }
                } catch {
                    break
                }
                break
            case .delete(let uuid):
                do {
                    if let recipe = self.recipes[uuid] {
                        let _ = try await API.deleteRecipe(recipe)
                    } else if let folder = self.folders[uuid] {
                        let _ = try await API.deleteFolder(folder)
                    }
                } catch {
                    break
                }
                break
            }
        }
        Self.logger.notice("Finished processing \(count) offline actions")
    }

    func removeUser() throws {
        // Clear out stored user info
        self.clearUser()
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

    func folder(id: ObjectID?) -> Folder? {
        guard let id else { return nil }
        if self.folders.contains(where: { $0.key == id }) {
            return self.folders[id]
        } else {
            return nil
        }
    }

    func recipe(id: ObjectID?) -> Recipe? {
        guard let id else { return nil }
        if self.recipes.contains(where: { $0.key == id }) {
            return self.recipes[id]
        } else {
            return nil
        }
    }

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

    func addFolder(
        name: String,
        parent: ObjectID?,
        recipes: [ObjectID] = [],
        subfolders: [ObjectID] = [],
    ) async throws -> Folder {
        var folder = Folder(
            parent: parent,
            name: name,
            recipes: recipes,
            subfolders: subfolders
        )
        Self.logger.notice(
            "Creating folder \"\(name)\" (ID: \(folder.uuid)) with parent \(parent?.description ?? "nil")"
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
            self.offlineQueue.pushBack(.create(folder.uuid))
        }

        // Add the folder to the tracked state
        self.folders[folder.uuid] = folder
        // Then link to its parent
        guard let parent = self.folder(id: folder.parent)
        else {
            Self.logger.error(
                "Missing parent \(folder.parent?.description ?? "nil") for folder \(folder.uuid)"
            )
            throw BasilError.missingFolder(folder.parent)
        }
        parent.addSubfolder(uuid: folder.uuid)
        self.store()
        return folder
    }

    func addFolder(
        _ folder: Folder
    ) async throws -> Folder {
        return try await self.addFolder(
            name: folder.name,
            parent: folder.parent,
            recipes: folder.recipes,
            subfolders: folder.subfolders
        )
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
            self.offlineQueue.pushBack(.create(recipe.uuid))
        }

        // Add the recipe to the tracked state
        self.recipes[recipe.uuid] = recipe
        // Then link to its parent
        guard let parent = self.folder(id: recipe.parent)
        else {
            Self.logger.error(
                "Missing parent \(recipe.parent) for recipe \(recipe.uuid)"
            )
            throw BasilError.missingFolder(recipe.parent)
        }
        parent.addRecipe(uuid: recipe.uuid)
        self.store()
        return recipe
    }

    func addRecipe(
        _ recipe: Recipe
    ) async throws -> Recipe {
        let ingredients = recipe.ingredients.map { $0.toString() }
        return try await self.addRecipe(
            title: recipe.title,
            parent: recipe.parent,
            ingredients: ingredients,
            instructions: recipe.instructions
        )
    }

    func updateFolder(folder: Folder) async throws {
        // If the user is online, send the action to the server
        if self.online {
            do {
                try await API.updateFolder(folder)
            } catch let error {
                Self.logger.error("Error updating folder: \(error)")
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
                "Adding offline action to modify folder \(folder.uuid)"
            )
            self.offlineQueue.pushBack(.modify(folder.uuid))
        }

        self.folders[folder.uuid] = folder
        self.store()
    }

    func updateRecipe(recipe: Recipe) async throws {
        // If the user is online, send the action to the server
        if self.online {
            do {
                try await API.updateRecipe(recipe)
            } catch let error {
                Self.logger.error("Error updating recipe: \(error)")
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
                "Adding offline action to modify recipe \(recipe.uuid)"
            )
            self.offlineQueue.pushBack(.modify(recipe.uuid))
        }

        self.recipes[recipe.uuid] = recipe
        self.store()
    }

    func deleteFolder(folder: Folder, recursive: Bool = true) async throws {
        Self.logger.notice(
            "Deleting folder \"\(folder.name)\" (ID: \(folder.uuid))"
        )

        if recursive {
            // Recursively delete children
            for recipeId in folder.recipes {
                if let recipe = self.recipe(id: recipeId) {
                    try await self.deleteRecipe(recipe: recipe)
                }
            }
            for folderId in folder.subfolders {
                if let folder = self.folder(id: folderId) {
                    try await self.deleteFolder(folder: folder)
                }
            }
        }

        // Remove the folder from its parent
        if let parent = folder.parent {
            self.folders[parent]?.removeSubfolder(uuid: folder.uuid)
        }

        // If the user is online, send the action to the server
        if self.online {
            do {
                try await API.deleteFolder(folder)
            } catch let error {
                Self.logger.error("Error deleting folder: \(error)")
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
                "Adding offline action to delete folder \(folder.uuid)"
            )
            self.offlineQueue.pushBack(.delete(folder.uuid))
        }

        self.folders.removeValue(forKey: folder.uuid)
        self.store()
    }

    func deleteRecipe(recipe: Recipe) async throws {
        Self.logger.notice(
            "Deleting recipe \"\(recipe.title)\" (ID: \(recipe.uuid))"
        )

        // Remove the recipe from its parent
        self.folders[recipe.parent]?.removeRecipe(uuid: recipe.uuid)

        // If the user is online, send the action to the server
        if self.online {
            do {
                try await API.deleteRecipe(recipe)
            } catch let error {
                Self.logger.error("Error deleting recipe: \(error)")
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
                "Adding offline action to delete recipe \(recipe.uuid)"
            )
            self.offlineQueue.pushBack(.delete(recipe.uuid))
        }

        self.recipes.removeValue(forKey: recipe.uuid)
        self.store()
    }

    func deleteItem(uuid: ObjectID) async throws {
        return try await self.deleteItems(uuids: [uuid])
    }

    func deleteItems(uuids: [ObjectID]) async throws {
        for uuid in uuids {
            if let recipe = self.recipe(id: uuid) {
                try await self.deleteRecipe(recipe: recipe)
            } else if let folder = self.folder(id: uuid) {
                try await self.deleteFolder(folder: folder)
            }
        }
    }

    func moveFolder(folder: Folder, to folderId: ObjectID) async throws {
        // First remove the folder
        try await self.deleteFolder(folder: folder, recursive: false)
        // Then create a new folder inside the new parent
        folder.parent = folderId
        let _ = try await self.addFolder(folder)
    }

    func moveRecipe(recipe: Recipe, to folderId: ObjectID) async throws {
        // First remove the recipe
        try await self.deleteRecipe(recipe: recipe)
        // Then create a new recipe inside the new parent
        recipe.parent = folderId
        let _ = try await self.addRecipe(recipe)
    }

    func moveItem(uuid: ObjectID, to folderId: ObjectID) async throws {
        try await self.moveItems(uuids: [uuid], to: folderId)
    }

    func moveItems(uuids: [ObjectID], to folderId: ObjectID) async throws {
        for item in uuids {
            if let folder = self.folders[item] {
                try await self.moveFolder(folder: folder, to: folderId)
            }
            if let recipe = self.recipes[item] {
                try await self.moveRecipe(recipe: recipe, to: folderId)
            }
        }
    }

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
        self.store()
    }

    func addToGroceryList(from recipe: Recipe) {
        self.groceryList.addIngredients(from: recipe)
        self.store()
    }

    func modifyGrocery(at indexPath: IndexPath, with grocery: Ingredient) {
        self.groceryList.modify(at: indexPath, with: grocery)
        self.store()
    }

    func replaceGrocery(at indexPath: IndexPath, with grocery: Ingredient)
        -> IndexPath
    {
        let indexPath = self.groceryList.replace(at: indexPath, with: grocery)
        self.store()
        return indexPath
    }

    func removeGrocery(at indexPath: IndexPath) {
        self.groceryList.remove(at: indexPath)
        self.store()
    }

    func removeAllGroceries() {
        self.groceryList.clear()
        self.store()
    }
}

extension StateManager: CustomStringConvertible {

    var description: String {
        return
            "StateManager(userEmail: \(self.userEmail), root: \(self.root?.description ?? "nil"), recipes: \(self.recipes), folders: \(self.folders))"
    }
}

extension StateManager.Action: CustomStringConvertible {

    var description: String {
        switch self {
        case .create(let uuid):
            return ".create(\(uuid))"
        case .modify(let uuid):
            return ".modify(\(uuid))"
        case .delete(let uuid):
            return ".delete(\(uuid))"
        }
    }
}

extension StateManager: Decodable {

    convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let userEmail = try values.decode(String.self, forKey: .userEmail)
        Self.logger.trace("StateManager: decoded userEmail: \(userEmail)")
        let root =
            try values.decodeIfPresent(ObjectID?.self, forKey: .root) ?? nil
        Self.logger.trace(
            "StateManager: decoded root: \(root?.description ?? "nil")"
        )
        let recipes = try values.decode([Recipe].self, forKey: .recipes)
        Self.logger.trace("StateManager: decoded recipes: \(recipes)")
        let folders = try values.decode([Folder].self, forKey: .folders)
        Self.logger.trace("StateManager: decoded folders: \(folders)")
        let offlineQueue = try values.decode(
            RingBuffer<Action>.self,
            forKey: .offlineQueue
        )
        let groceryList = try values.decode(
            GroceryList.self,
            forKey: .groceryList
        )

        self.init(
            userEmail: userEmail,
            root: root,
            recipes: recipes,
            folders: folders,
            offlineQueue: offlineQueue,
            groceryList: groceryList
        )
    }
}

extension StateManager: Encodable {

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let recipes = Array(self.recipes.values)
        let folders = Array(self.folders.values)

        try container.encode(self.userEmail, forKey: .userEmail)
        try container.encode(self.root, forKey: .root)
        try container.encode(recipes, forKey: .recipes)
        try container.encode(folders, forKey: .folders)
        try container.encode(self.offlineQueue, forKey: .offlineQueue)
        try container.encode(self.groceryList, forKey: .groceryList)
    }
}
