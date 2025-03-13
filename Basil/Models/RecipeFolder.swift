//
//  RecipeFolder.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/29/23.
//

import UIKit

class RecipeFolder: Codable {

    let uuid: UUID
    var folderId: UUID?
    var name: String
    var recipes: [UUID]
    var subfolders: [UUID]

    init(folderId: UUID?, name: String, recipes: [UUID] = [], subfolders: [UUID] = []) {
        self.uuid = UUID()
        self.folderId = folderId
        self.name = name
        self.recipes = recipes
        self.subfolders = subfolders
    }

    func addRecipe(uuid: UUID) {
        self.recipes.append(uuid)
    }

    func addSubfolder(uuid: UUID) {
        self.subfolders.append(uuid)
    }

    func removeRecipe(uuid: UUID) {
        self.recipes.removeAll { $0 == uuid }
    }

    func removeSubfolder(uuid: UUID) {
        self.subfolders.removeAll { $0 == uuid }
    }

    func update(with other: RecipeFolder) {
        self.folderId = other.folderId
        self.name = other.name
        self.recipes = other.recipes
        self.subfolders = other.subfolders
    }

    static func == (lhs: RecipeFolder, rhs: RecipeFolder) -> Bool {
        return lhs.uuid == rhs.uuid
    }

    static func sort(_ this: RecipeFolder, _ that: RecipeFolder) -> Bool {
        return this.name < that.name
    }

    static func sortReverse(_ this: RecipeFolder, _ that: RecipeFolder) -> Bool {
        return !RecipeFolder.sort(this, that)
    }
}

extension RecipeFolder: Hashable {
    var identifier: String {
        return self.uuid.uuidString
    }

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(self.identifier)
    }
}
