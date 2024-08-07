//
//  Recipe.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/23/23.
//

import Foundation

class Recipe: Codable {
    var uuid: UUID
    var folderId: UUID
    var title: String
    var ingredients: [Ingredient]
    var instructions: [String]

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
