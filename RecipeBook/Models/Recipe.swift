//
//  Recipe.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/23/23.
//

import Foundation

struct Recipe: Codable {
    let title: String
    // TODO: create a custom type that allows for sub-sections
    let ingredients: [String]
    // TODO: create a custom type that allows for sub-sections
    let instructions: [String]
}
