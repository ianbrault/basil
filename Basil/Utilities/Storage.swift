//
//  Storage.swift
//  Basil
//
//  Created by Ian Brault on 6/12/26.
//

import Foundation
import os

//
// Enum used for accessing UserDefaults
//
struct Storage {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Storage.self)
    )

    enum Key {
        static let hasLaunched = "hasLaunched"
        static let settings = "settings"
        static let state = "state"
    }

    static let defaults = UserDefaults.standard

    static func getObject<T: CustomStringConvertible & Decodable>(
        forKey key: String
    ) -> T? {
        if let data = UserDefaults.standard.object(forKey: key) as? Data {
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                Self.logger.debug("Storage.getObject: \(key): \(decoded)")
                return decoded
            } catch let error {
                Self.logger.error(
                    "Storage: failed to decode object for key: \(key): \(error)"
                )
                return nil
            }
        } else {
            Self.logger.info("Storage: missing object for key: \(key)")
            return nil
        }
    }

    static func setObject<T: CustomStringConvertible & Encodable>(
        _ value: T,
        forKey key: String
    ) {
        Self.logger.debug("Storage.setObject: \(key): \(value)")
        let encoded = try! JSONEncoder().encode(value)
        UserDefaults.standard.set(encoded, forKey: key)
    }
}
