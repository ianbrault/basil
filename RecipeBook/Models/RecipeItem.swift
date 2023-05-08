//
//  RecipeItem.swift
//  RecipeBook
//
//  Created by Ian Brault on 5/1/23.
//

import Foundation

enum RecipeItem: Codable {
    case recipe(Recipe)
    case folder(RecipeFolder)

    var uuid: UUID {
        switch self {
        case .recipe(let recipe):
            return recipe.uuid
        case .folder(let folder):
            return folder.uuid
        }
    }

    var folderId: UUID? {
        switch self {
        case .recipe(let recipe):
            return recipe.folderId
        case .folder(let folder):
            return folder.folderId
        }
    }

    var isRecipe: Bool {
        switch self {
        case .recipe(_):
            return true
        case .folder(_):
            return false
        }
    }

    func intoRecipe() -> Recipe? {
        switch self {
        case .recipe(let recipe):
            return recipe
        case .folder(_):
            return nil
        }
    }

    func intoFolder() -> RecipeFolder? {
        switch self {
        case .recipe(_):
            return nil
        case .folder(let folder):
            return folder
        }
    }

    static func sort(_ this: RecipeItem, _ that: RecipeItem) -> Bool {
        // folders always come before recipes
        switch (this, that) {
        case (.recipe(let recipeA), .recipe(let recipeB)):
            return Recipe.sort(recipeA, recipeB)
        case (.recipe(_), .folder(_)):
            return false
        case (.folder(_), .recipe(_)):
            return true
        case (.folder(let folderA), .folder(let folderB)):
            return RecipeFolder.sort(folderA, folderB)
        }
    }
}
