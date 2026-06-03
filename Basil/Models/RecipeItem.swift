//
//  RecipeItem.swift
//  RecipeBook
//
//  Created by Ian Brault on 5/1/23.
//

import Foundation

enum RecipeItem: Codable & Equatable & Hashable {
    case recipe(Recipe)
    case folder(Folder)

    var uuid: ObjectID {
        switch self {
        case .recipe(let recipe):
            return recipe.uuid
        case .folder(let folder):
            return folder.uuid
        }
    }

    var parent: ObjectID? {
        get {
            switch self {
            case .recipe(let recipe):
                return recipe.parent
            case .folder(let folder):
                return folder.parent
            }
        }
        set {
            switch self {
            case .recipe(let recipe):
                recipe.parent = newValue!
            case .folder(let folder):
                folder.parent = newValue
            }
        }
    }

    var text: String {
        switch self {
        case .recipe(let recipe):
            return recipe.title
        case .folder(let folder):
            return folder.name
        }
    }

    func includesText(_ string: String) -> Bool {
        return self.text.lowercased().contains(string.lowercased())
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
            return Folder.sort(folderA, folderB)
        }
    }

    static func sortReverse(_ this: RecipeItem, _ that: RecipeItem) -> Bool {
        return !RecipeItem.sort(this, that)
    }
}
