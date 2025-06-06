//
//  RecipeFolder.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/29/23.
//

import UIKit

final class RecipeFolder {

    let uuid: UUID
    var folderId: UUID?
    var name: String
    var recipes: [UUID]
    var subfolders: [UUID]

    enum CodingKeys: String, CodingKey {
        case uuid
        case folderId
        case name
        case recipes
        case subfolders
    }

    init(folderId: UUID?, name: String, recipes: [UUID] = [], subfolders: [UUID] = []) {
        self.uuid = UUID()
        self.folderId = folderId
        self.name = name
        self.recipes = recipes
        self.subfolders = subfolders
    }

    fileprivate init(uuid: UUID, folderId: UUID?, name: String, recipes: [UUID] = [], subfolders: [UUID] = []) {
        self.uuid = uuid
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

extension RecipeFolder: Decodable {
    convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let uuid = try values.decode(UUID.self, forKey: .uuid)
        let folderId = try values.decodeIfPresent(UUID?.self, forKey: .folderId) ?? nil
        let name = try values.decode(String.self, forKey: .name)
        let recipes = try values.decode([UUID].self, forKey: .recipes)
        let subfolders = try values.decode([UUID].self, forKey: .subfolders)

        self.init(uuid: uuid, folderId: folderId, name: name, recipes: recipes, subfolders: subfolders)
    }
}

extension RecipeFolder: Encodable {
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.uuid, forKey: .uuid)
        try container.encode(self.folderId, forKey: .folderId)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.recipes, forKey: .recipes)
        try container.encode(self.subfolders, forKey: .subfolders)
    }
}
