//
//  Folder.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/29/23.
//

import UIKit

final class Folder {

    let uuid: ObjectID
    var parent: ObjectID?
    var name: String
    var recipes: [ObjectID]
    var subfolders: [ObjectID]

    enum CodingKeys: String, CodingKey {
        case uuid
        case parent
        case name
        case recipes
        case subfolders
    }

    init(
        parent: ObjectID?,
        name: String,
        recipes: [ObjectID] = [],
        subfolders: [ObjectID] = []
    ) {
        self.uuid = ObjectID()
        self.parent = parent
        self.name = name
        self.recipes = recipes
        self.subfolders = subfolders
    }

    init(
        uuid: ObjectID,
        parent: ObjectID?,
        name: String,
        recipes: [ObjectID] = [],
        subfolders: [ObjectID] = []
    ) {
        self.uuid = uuid
        self.parent = parent
        self.name = name
        self.recipes = recipes
        self.subfolders = subfolders
    }

    convenience init(response: API.FolderResponse) {
        self.init(
            uuid: response._id,
            parent: response.parent,
            name: response.name,
            recipes: response.recipes,
            subfolders: response.subfolders
        )
    }

    func addRecipe(uuid: ObjectID) {
        self.recipes.append(uuid)
    }

    func addSubfolder(uuid: ObjectID) {
        self.subfolders.append(uuid)
    }

    func removeRecipe(uuid: ObjectID) {
        self.recipes.removeAll { $0 == uuid }
    }

    func removeSubfolder(uuid: ObjectID) {
        self.subfolders.removeAll { $0 == uuid }
    }

    func update(with other: Folder) {
        self.parent = other.parent
        self.name = other.name
        self.recipes = other.recipes
        self.subfolders = other.subfolders
    }

    static func == (lhs: Folder, rhs: Folder) -> Bool {
        return lhs.uuid == rhs.uuid
    }

    static func sort(_ this: Folder, _ that: Folder) -> Bool {
        return this.name < that.name
    }

    static func sortReverse(_ this: Folder, _ that: Folder) -> Bool {
        return !Self.sort(this, that)
    }
}

extension Folder: Hashable {
    var identifier: String {
        return self.uuid.description
    }

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(self.identifier)
    }
}

extension Folder: Decodable {
    convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let uuid = try values.decode(ObjectID.self, forKey: .uuid)
        let parent =
            try values.decodeIfPresent(ObjectID?.self, forKey: .parent) ?? nil
        let name = try values.decode(String.self, forKey: .name)
        let recipes = try values.decode([ObjectID].self, forKey: .recipes)
        let subfolders = try values.decode([ObjectID].self, forKey: .subfolders)

        self.init(
            uuid: uuid,
            parent: parent,
            name: name,
            recipes: recipes,
            subfolders: subfolders
        )
    }
}

extension Folder: Encodable {
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.uuid, forKey: .uuid)
        try container.encode(self.parent, forKey: .parent)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.recipes, forKey: .recipes)
        try container.encode(self.subfolders, forKey: .subfolders)
    }
}
