//
//  RecipeFolder.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/29/23.
//

import Foundation

class RecipeFolder: Codable {
    let uuid: UUID
    let folderId: UUID?
    let name: String
    var items: [UUID]

    init(uuid: UUID, folderId: UUID?, name: String, items: [UUID]) {
        self.uuid = uuid
        self.folderId = folderId
        self.name = name
        self.items = items
    }

    static func root() -> RecipeFolder {
        return RecipeFolder(uuid: UUID(), folderId: nil, name: "", items: [])
    }

    func addItem(uuid: UUID) {
        self.items.append(uuid)
    }

    func removeItem(uuid: UUID) {
        self.items.removeAll { $0 == uuid }
    }
}
