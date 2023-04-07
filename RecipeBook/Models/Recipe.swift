//
//  Recipe.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/23/23.
//

import Foundation

struct Recipe: Codable {
    let title: String
    let ingredients: [Ingredient]
    let instructions: [Instruction]
}
