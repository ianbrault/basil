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

    private enum Keys {
        static let dataVersion = "dataVersion"
        static let groceryList = "groceryList"
        static let hasLaunched = "hasLaunched"
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
                print("ERROR: invalid grocery list: \(error): continuing with an empty list")
                return GroceryList()
            }
        }
        set {
            // NOTE: unwrap the JSONEncoder result, we should never have invalid JSON data
            let encoded = try! self.encoder.encode(newValue)
            self.defaults.set(encoded, forKey: Keys.groceryList)
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

    var state: State.Storage {
        get {
            guard let stateData = self.defaults.object(forKey: Keys.state) as? Data else {
                // if this is nil, nothing has been saved before
                return .empty()
            }
            // NOTE: this should always be valid JSON
            // TODO: consider unwrapping instead of failing silently
            do {
                return try self.decoder.decode(State.Storage.self, from: stateData)
            } catch {
                print("ERROR: invalid state: \(error): continuing with an empty state")
                return .empty()
            }
        }
        set {
            // store the data version alongside the state
            self.defaults.set(self.dataVersion, forKey: Keys.dataVersion)
            // NOTE: unwrap the JSONEncoder result, we should never have invalid JSON data
            let encoded = try! self.encoder.encode(newValue)
            self.defaults.set(encoded, forKey: Keys.state)
        }
    }

    // Keychain access functions

    func keychainStatus(_ status: OSStatus) -> BasilError? {
        if status == errSecSuccess {
            return nil
        } else {
            let message = SecCopyErrorMessageString(status, nil) as? String ?? ""
            return .keychainError(message)
        }
    }

    func storePassword(email: String, password: String) -> BasilError? {
        guard let password = password.data(using: .utf8) else {
            return .encodeError
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: email,
            kSecAttrServer as String: NetworkManager.baseURL.absoluteString,
            kSecValueData as String: password,
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem {
            // a password already exists in the keychain, overwrite it
            let query: [String: Any] = [
                kSecClass as String: kSecClassInternetPassword,
                kSecAttrServer as String: NetworkManager.baseURL.absoluteString,
            ]
            let attributes: [String: Any] = [
                kSecAttrAccount as String: email,
                kSecValueData as String: password,
            ]
            let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            return keychainStatus(status)
        } else {
            return keychainStatus(status)
        }
    }

    func fetchPassword(email: String) -> Result<String, BasilError> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: NetworkManager.baseURL.absoluteString,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess {
            guard let item = item as? [String: Any],
                  let passwordData = item[kSecValueData as String] as? Data,
                  let password = String(data: passwordData, encoding: .utf8)
            else {
                return .failure(.keychainError("Unexpected password data"))
            }
            return .success(password)
        } else {
            return .failure(keychainStatus(status)!)
        }
    }

    func deletePassword(email: String) {
        // first retrieve the password
        switch fetchPassword(email: email) {
        case .success(let password):
            let query: [String: Any] = [
                kSecClass as String: kSecClassInternetPassword,
                kSecAttrAccount as String: email,
                kSecAttrServer as String: NetworkManager.baseURL.absoluteString,
                kSecValueData as String: password,
            ]
            let _ = SecItemDelete(query as CFDictionary)
        case .failure(_):
            // ignore error return, if the password failed to be retrieved, there is no need
            // to worry about it being deleted
            return

        }
    }
}
