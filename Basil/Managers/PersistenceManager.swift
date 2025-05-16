//
//  PersistenceManager.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/6/23.
//

import Foundation

//
// Singleton class responsible for managing the storage/retrieval of persistent state using the UserDefaults API
// Member variables are getters/setters which store to or retrieve from persistent storage
// Versioned to allow for backwards compatibility
//
class PersistenceManager {

    static let shared = PersistenceManager()
    static let version = 2

    private let defaults = UserDefaults.standard
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    enum Keys {
        static let dataVersion = "dataVersion"
        static let hasLaunched = "hasLaunched"
        static let root = "root"
        static let recipes = "recipes"
        static let folders = "folders"
        static let sequence = "sequence"
        static let groceryList = "groceryList"
        // deprecated but key is retained for use in migrations
        static let state = "state"
    }

    var dataVersion: Int {
        get {
            return self.defaults.integer(forKey: Keys.dataVersion)
        }
        set {
            self.defaults.set(newValue, forKey: Keys.dataVersion)
        }
    }

    var hasLaunched: Bool {
        get {
            return self.defaults.bool(forKey: Keys.hasLaunched)
        }
        set {
            self.defaults.set(newValue, forKey: Keys.hasLaunched)
        }
    }

    var root: UUID? {
        get {
            guard let rootString = self.defaults.string(forKey: Keys.root) else {
                return nil
            }
            return UUID(uuidString: rootString)
        }
        set {
            self.defaults.set(newValue?.uuidString, forKey: Keys.root)
        }
    }

    var recipes: [Recipe] {
        get {
            return self.getObject(forKey: Keys.recipes, defaultValue: [])
        }
        set {
            self.setObject(newValue, forKey: Keys.recipes)
        }
    }

    var folders: [RecipeFolder] {
        get {
            return self.getObject(forKey: Keys.folders, defaultValue: [])
        }
        set {
            self.setObject(newValue, forKey: Keys.folders)
        }
    }

    var sequence: Int {
        get {
            return self.defaults.integer(forKey: Keys.sequence)
        }
        set {
            self.defaults.set(newValue, forKey: Keys.sequence)
        }
    }

    var groceryList: GroceryList {
        get {
            return self.getObject(forKey: Keys.groceryList, defaultValue: GroceryList())
        }
        set {
            self.setObject(newValue, forKey: Keys.groceryList)
        }
    }

    func getObject<T: Codable>(forKey key: String, defaultValue: T) -> T {
        guard let data = self.defaults.object(forKey: key) as? Data else {
            return defaultValue
        }
        do {
            return try self.decoder.decode(T.self, from: data)
        } catch {
            return defaultValue
        }
    }

    func setObject<T: Codable>(_ value: T, forKey key: String) {
        let encoded = try! self.encoder.encode(value)
        self.defaults.set(encoded, forKey: key)
    }
}
