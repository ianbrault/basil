//
//  PersistenceManager.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/6/23.
//

import Foundation

enum PersistenceManager {
    static private let defaults = UserDefaults.standard
    static private let dataVersion = 1

    enum Keys {
        static let dataVersion = "dataVersion"
        static let needsToUpdateServer = "needsToUpdateServer"
        static let state = "state"
    }

    static func loadDataVersion() -> Int {
        return self.defaults.integer(forKey: Keys.dataVersion)
    }

    static func loadNeedsToUpdateServer() -> Bool {
        return self.defaults.bool(forKey: Keys.needsToUpdateServer)
    }

    static func loadState() -> Result<State.Data, RBError> {
        guard let stateData = self.defaults.object(forKey: Keys.state) as? Data else {
            // if this is nil, nothing has been saved before
            return .success(.empty())
        }

        do {
            let decoder = JSONDecoder()
            let state = try decoder.decode(State.Data.self, from: stateData)
            return .success(state)
        } catch {
            // NOTE: this should be updated at some point in the future, but since we are
            // iterating at the moment, clear out the state when the data format changes
            print("ERROR: failed to decode state: \(error.localizedDescription)")
            return .success(.empty())
        }
    }

    static func storeDataVersion(_ version: Int) {
        self.defaults.set(version, forKey: Keys.dataVersion)
    }

    static func storeNeedsToUpdateServer(_ value: Bool) {
        self.defaults.set(value, forKey: Keys.needsToUpdateServer)
    }

    static func storeState(state: State.Data) {
        // store the data version alongside the state
        self.defaults.set(self.dataVersion, forKey: Keys.dataVersion)

        let encoder = JSONEncoder()
        // NOTE: unwrap the JSONEncoder result, we should never have invalid JSON data
        let encodedState = try! encoder.encode(state)
        self.defaults.set(encodedState, forKey: Keys.state)
    }
}
