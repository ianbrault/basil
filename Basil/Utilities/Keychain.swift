//
//  Keychain.swift
//  Basil
//
//  Created by Ian Brault on 5/13/25.
//

import Foundation
import os

struct Keychain {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Keychain.self)
    )

    static let accessGroup = "group.com.isft.Basil"

    struct Credentials {
        let email: String
        let password: String
    }

    static func getCredentials(email: String) throws -> Credentials {
        var item: CFTypeRef?
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: Network.baseURL.absoluteString,
            kSecAttrAccessGroup as String: Self.accessGroup,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
        ]
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        self.logger.debug("Keychain.getCredentials: status: \(status)")
        if status == errSecItemNotFound {
            throw BasilError.keychainError(errSecItemNotFound)
        } else if status != errSecSuccess {
            throw BasilError.keychainError(status)
        }

        for i in 0..<(item?.count ?? 0) {
            guard let credentialItem = item?[i] as? NSMutableDictionary,
                let itemEmail = credentialItem[kSecAttrAccount] as? String,
                let passwordData = credentialItem[kSecValueData] as? Data,
                let password = String(
                    data: passwordData,
                    encoding: String.Encoding.utf8
                )
            else {
                throw BasilError.keychainError(errSecInvalidData)
            }
            if itemEmail == email {
                return Credentials(email: email, password: password)
            }
        }
        throw BasilError.keychainError(errSecItemNotFound)
    }

    static func setCredentials(email: String, password: String) throws {
        guard let password = password.data(using: String.Encoding.utf8) else {
            throw BasilError.encodeError
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: Network.baseURL.absoluteString,
            kSecAttrAccessGroup as String: Self.accessGroup,
            kSecAttrAccount as String: email,
            kSecValueData as String: password,
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        self.logger.debug(
            "Keychain.setCredentials: email: \(email): status: \(status)"
        )
        if status != errSecSuccess {
            throw BasilError.keychainError(status)
        }
    }

    static func deleteCredentials() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: Network.baseURL.absoluteString,
            kSecAttrAccessGroup as String: Self.accessGroup,
        ]
        let status = SecItemDelete(query as CFDictionary)
        self.logger.debug("Keychain.deleteCredentials: status: \(status)")
        if status != errSecSuccess && status != errSecItemNotFound {
            throw BasilError.keychainError(status)
        }
    }
}
