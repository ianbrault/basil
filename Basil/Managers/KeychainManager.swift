//
//  KeychainManager.swift
//  Basil
//
//  Created by Ian Brault on 5/13/25.
//

import Foundation

struct KeychainManager {

    static let accessGroup = "group.com.isft.Basil"

    struct Credentials {
        let email: String
        let password: String
    }

    static func getCredentials() throws -> Credentials? {
        var item: CFTypeRef?
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: NetworkManager.baseURL.absoluteString,
            kSecAttrAccessGroup as String: Self.accessGroup,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
        ]
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return nil
        } else if status != errSecSuccess {
            throw BasilError.keychainError(status)
        }
        guard let credentialItem = item as? [String : Any],
              let passwordData = credentialItem[kSecValueData as String] as? Data,
              let password = String(data: passwordData, encoding: String.Encoding.utf8),
              let email = credentialItem[kSecAttrAccount as String] as? String
        else {
            throw BasilError.keychainError(errSecInvalidData)
        }
        return Credentials(email: email, password: password)
    }

    static func setCredentials(email: String, password: String) throws {
        guard let password = password.data(using: String.Encoding.utf8) else {
            throw BasilError.encodeError
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: NetworkManager.baseURL.absoluteString,
            kSecAttrAccessGroup as String: Self.accessGroup,
            kSecAttrAccount as String: email,
            kSecValueData as String: password,
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            throw BasilError.keychainError(status)
        }
    }

    static func deleteCredentials() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: NetworkManager.baseURL.absoluteString,
            kSecAttrAccessGroup as String: Self.accessGroup,
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw BasilError.keychainError(status)
        }
    }
}
