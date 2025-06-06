//
//  Recipe.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/23/23.
//

import Foundation

final class Recipe {

    var uuid: UUID
    var folderId: UUID
    var title: String
    var ingredients: [Ingredient]
    var instructions: [String]

    enum CodingKeys: String, CodingKey {
        case uuid
        case folderId
        case title
        case ingredients
        case instructions
    }

    init(uuid: UUID, folderId: UUID, title: String, ingredients: [Ingredient] = [], instructions: [String] = []) {
        self.uuid = uuid
        self.folderId = folderId
        self.title = title
        self.ingredients = ingredients
        self.instructions = instructions
    }

    convenience init(folderId: UUID, title: String, ingredients: [Ingredient] = [], instructions: [String] = []) {
        self.init(uuid: UUID(), folderId: folderId, title: title, ingredients: ingredients, instructions: instructions)
    }

    func update(with other: Recipe) {
        self.folderId = other.folderId
        self.title = other.title
        self.ingredients = other.ingredients
        self.instructions = other.instructions
    }

    static func == (lhs: Recipe, rhs: Recipe) -> Bool {
        return lhs.uuid == rhs.uuid
    }

    static func sort(_ this: Recipe, _ that: Recipe) -> Bool {
        return this.title < that.title
    }

    static func sortReverse(_ this: Recipe, _ that: Recipe) -> Bool {
        return !Recipe.sort(this, that)
    }
}

extension Recipe: Hashable {
    var identifier: String {
        return self.uuid.uuidString
    }

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(self.identifier)
    }
}

extension Recipe: Decodable {
    convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let uuid = try values.decode(UUID.self, forKey: .uuid)
        let folderId = try values.decode(UUID.self, forKey: .folderId)
        let title = try values.decode(String.self, forKey: .title)
        let ingredients = try values.decode([Ingredient].self, forKey: .ingredients)
        let instructions = try values.decode([String].self, forKey: .instructions)

        self.init(uuid: uuid, folderId: folderId, title: title, ingredients: ingredients, instructions: instructions)
    }
}

extension Recipe: Encodable {
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.uuid, forKey: .uuid)
        try container.encode(self.folderId, forKey: .folderId)
        try container.encode(self.title, forKey: .title)
        try container.encode(self.ingredients, forKey: .ingredients)
        try container.encode(self.instructions, forKey: .instructions)
    }
}
