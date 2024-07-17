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

    private let defaults = UserDefaults.standard
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let version = 1

    private enum Keys {
        static let dataVersion = "dataVersion"
        static let groceryList = "groceryList"
        static let needsToUpdateServer = "needsToUpdateServer"
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

    var groceryList: GroceryList {
        get {
            guard let groceryData = self.defaults.object(forKey: Keys.groceryList) as? Data else {
                return GroceryList()
            }
            // NOTE: this should always be valid JSON
            // TODO: consider unwrapping instead of failing silently
            do {
                return try self.decoder.decode(GroceryList.self, from: groceryData)
            } catch {
                print("ERROR: invalid grocery list, continuing with an empty list")
                return GroceryList()
            }
        }
        set {
            // NOTE: unwrap the JSONEncoder result, we should never have invalid JSON data
            let encoded = try! self.encoder.encode(newValue)
            self.defaults.set(encoded, forKey: Keys.groceryList)
        }
    }

    var needsToUpdateServer: Bool {
        get {
            return self.defaults.bool(forKey: Keys.needsToUpdateServer)
        }
        set {
            self.defaults.set(newValue, forKey: Keys.needsToUpdateServer)
        }
    }

    var state: State.Data {
        get {
            guard let stateData = self.defaults.object(forKey: Keys.state) as? Data else {
                // if this is nil, nothing has been saved before
                return .empty()
            }
            // NOTE: an assumption is made that the stored state is valid JSON; this will be true
            // unless the data version is out of date, so this relies on that case being handled
            // during initialization at a higher level
            return try! self.decoder.decode(State.Data.self, from: stateData)
        }
        set {
            // store the data version alongside the state
            self.defaults.set(self.dataVersion, forKey: Keys.dataVersion)
            // NOTE: unwrap the JSONEncoder result, we should never have invalid JSON data
            let encoded = try! self.encoder.encode(newValue)
            self.defaults.set(encoded, forKey: Keys.state)
        }
    }
}
