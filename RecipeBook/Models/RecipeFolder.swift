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
    var name: String
    var items: [UUID]

    init(folderId: UUID?, name: String, items: [UUID] = []) {
        self.uuid = UUID()
        self.folderId = folderId
        self.name = name
        self.items = items
    }

    static func root() -> RecipeFolder {
        return RecipeFolder(folderId: nil, name: "")
    }

    func addItem(uuid: UUID) {
        self.items.append(uuid)
    }

    func removeItem(uuid: UUID) {
        self.items.removeAll { $0 == uuid }
    }

    static func sort(_ this: RecipeFolder, _ that: RecipeFolder) -> Bool {
        return this.name < that.name
    }
}
