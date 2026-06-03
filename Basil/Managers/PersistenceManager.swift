//
//  PersistenceManager.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/6/23.
//

import Foundation
import os

//
// Singleton class responsible for managing the storage/retrieval of persistent state using the UserDefaults API
// Member variables are getters/setters which store to or retrieve from persistent storage
// Versioned to allow for backwards compatibility
//
class PersistenceManager {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: PersistenceManager.self)
    )

    static let shared = PersistenceManager()
    static let version = 2

    enum Keys {
        static let dataVersion = "dataVersion"
        static let email = "email"
        static let hasLaunched = "hasLaunched"
        static let root = "root"
        static let recipes = "recipes"
        static let folders = "folders"
        static let offlineQueue = "offlineQueue"
        static let groceryList = "groceryList"
        // Settings
        static let sortCheckedGroceries = "sortCheckedGroceries"
    }

    private init() {
        // Set "non-default defaults" here
        UserDefaults.standard.register(defaults: [
            Keys.sortCheckedGroceries: true
        ])
    }

    func getObject<T: Codable>(forKey key: String) -> T? {
        guard let data = UserDefaults.standard.object(forKey: key) as? Data
        else {
            return nil
        }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func setObject<T: Codable>(_ value: T, forKey key: String) {
        let encoded = try! JSONEncoder().encode(value)
        UserDefaults.standard.set(encoded, forKey: key)
    }

    //
    // Persistence object getters/setters
    //

    var dataVersion: Int {
        get {
            return UserDefaults.standard.integer(forKey: Keys.dataVersion)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.dataVersion)
        }
    }

    var email: String? {
        get {
            return UserDefaults.standard.string(forKey: Keys.email)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.email)
        }
    }

    var hasLaunched: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Keys.hasLaunched)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.hasLaunched)
        }
    }

    var root: ObjectID? {
        get {
            if let id = UserDefaults.standard.string(forKey: Keys.root) {
                return ObjectID(string: id)
            } else {
                return nil
            }
        }
        set {
            UserDefaults.standard.set(newValue?.description, forKey: Keys.root)
        }
    }

    var recipes: [ObjectID: Recipe] {
        get {
            return self.getObject(forKey: Keys.recipes) ?? [:]
        }
        set {
            self.setObject(newValue, forKey: Keys.recipes)
        }
    }

    var folders: [ObjectID: Folder] {
        get {
            return self.getObject(forKey: Keys.folders) ?? [:]
        }
        set {
            self.setObject(newValue, forKey: Keys.folders)
        }
    }

    var offlineQueue: RingBuffer<StateManager.Action> {
        get {
            if let queue: RingBuffer<StateManager.Action> = self.getObject(
                forKey: Keys.offlineQueue
            ) {
                return queue
            } else {
                Self.logger.warning(
                    "Failed to load object for key \(Keys.offlineQueue), creating default object"
                )
                return RingBuffer(size: StateManager.offlineQueueSize)
            }
        }
        set {
            self.setObject(newValue, forKey: Keys.offlineQueue)
        }
    }

    var groceryList: GroceryList {
        get {
            if let list: GroceryList = self.getObject(forKey: Keys.groceryList)
            {
                return list
            } else {
                Self.logger.warning(
                    "Failed to load object for key \(Keys.groceryList), creating default object"
                )
                return GroceryList()
            }
        }
        set {
            self.setObject(newValue, forKey: Keys.groceryList)
        }
    }

    var sortCheckedGroceries: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Keys.sortCheckedGroceries)
        }
        set {
            UserDefaults.standard.set(
                newValue,
                forKey: Keys.sortCheckedGroceries
            )
        }
    }
}
