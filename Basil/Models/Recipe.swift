//
//  Recipe.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/23/23.
//

import Foundation

final class Recipe {

    static let sectionHeader = "__SECTION__"

    var uuid: ObjectID
    var parent: ObjectID
    var title: String
    var ingredients: [Ingredient]
    var instructions: [String]

    enum CodingKeys: String, CodingKey {
        case uuid
        case parent
        case title
        case ingredients
        case instructions
    }

    init(
        uuid: ObjectID,
        parent: ObjectID,
        title: String,
        ingredients: [Ingredient] = [],
        instructions: [String] = []
    ) {
        self.uuid = uuid
        self.parent = parent
        self.title = title
        self.ingredients = ingredients
        self.instructions = instructions
    }

    init(
        parent: ObjectID,
        title: String,
        ingredients: [Ingredient] = [],
        instructions: [String] = []
    ) {
        self.uuid = ObjectID()
        self.parent = parent
        self.title = title
        self.ingredients = ingredients
        self.instructions = instructions
    }

    convenience init(response: API.RecipeResponse) {
        let ingredients = response.ingredients.map {
            IngredientParser.shared.parse(string: $0)
        }
        self.init(
            uuid: response._id,
            parent: response.parent,
            title: response.title,
            ingredients: ingredients,
            instructions: response.instructions
        )
    }

    func update(with other: Recipe) {
        self.parent = other.parent
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
        return !Self.sort(this, that)
    }
}

extension Recipe: Hashable {
    var identifier: String {
        return self.uuid.description
    }

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(self.identifier)
    }
}

extension Recipe: Decodable {
    convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let uuid = try values.decode(ObjectID.self, forKey: .uuid)
        let parent = try values.decode(ObjectID.self, forKey: .parent)
        let title = try values.decode(String.self, forKey: .title)
        let ingredients = try values.decode(
            [Ingredient].self,
            forKey: .ingredients
        )
        let instructions = try values.decode(
            [String].self,
            forKey: .instructions
        )

        self.init(
            uuid: uuid,
            parent: parent,
            title: title,
            ingredients: ingredients,
            instructions: instructions
        )
    }
}

extension Recipe: Encodable {
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.uuid, forKey: .uuid)
        try container.encode(self.parent, forKey: .parent)
        try container.encode(self.title, forKey: .title)
        try container.encode(self.ingredients, forKey: .ingredients)
        try container.encode(self.instructions, forKey: .instructions)
    }
}

extension Recipe: CustomStringConvertible {
    var description: String {
        return
            "Recipe(id: \(self.uuid), parent: \(self.parent), title: \"\(self.title)\", ingredients: \(self.ingredients), instructions: \(self.instructions)"
    }
}
