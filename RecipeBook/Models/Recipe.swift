//
//  Recipe.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/23/23.
//

import Foundation

struct Recipe: Codable {
    let uuid: UUID
    var folderId: UUID
    let title: String
    let ingredients: [Ingredient]
    let instructions: [Instruction]

    static func sort(_ this: Recipe, _ that: Recipe) -> Bool {
        return this.title < that.title
    }
}
