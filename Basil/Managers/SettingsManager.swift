//
//  SettingsManager.swift
//  Basil
//
//  Created by Ian Brault on 6/14/26.
//

import Foundation

//
// Singleton class responsible for managing user settings
//
class SettingsManager: Codable {

    static let shared =
        Storage.getObject(forKey: Storage.Key.settings) ?? SettingsManager()

    var sortCheckedGroceries = true

    private init() {}
}

extension SettingsManager: CustomStringConvertible {
    var description: String {
        return "SettingsManager(sortCheckedGroceries: \(self.sortCheckedGroceries))"
    }
}
