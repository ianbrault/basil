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
        static let state = "state"
    }

    static func loadDataVersion() -> Int {
        return self.defaults.integer(forKey: Keys.dataVersion)
    }

    static func loadState() -> Result<State.Data, RBError> {
        guard let stateData = self.defaults.object(forKey: Keys.state) as? Data else {
            // if this is nil, nothing has been saved before
            return .success(.empty())
        }

        if let string = String(data: stateData, encoding: String.Encoding.utf8) {
          print(string)
        }

        do {
            let decoder = JSONDecoder()
            let state = try decoder.decode(State.Data.self, from: stateData)
            return .success(state)
        } catch {
            // NOTE: this should be updated at some point in the future, but since we are
            // iterating at the moment, clear out the state when the data format changes
            return .success(.empty())
        }
    }

    static func storeState(state: State.Data) -> RBError? {
        // store the data version alongside the state
        self.defaults.set(self.dataVersion, forKey: Keys.dataVersion)

        do {
            let encoder = JSONEncoder()
            let encodedState = try encoder.encode(state)
            self.defaults.set(encodedState, forKey: Keys.state)
            return nil
        } catch {
            return .failedToSaveRecipes
        }
    }
}
