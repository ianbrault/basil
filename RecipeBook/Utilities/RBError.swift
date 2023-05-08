//
//  RBError.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/6/23.
//

import Foundation

enum RBError: Error {
    case cannotDeleteRoot
    case failedToLoadRecipes
    case failedToSaveRecipes
    case missingInput(UUID)
    case missingRecipe(UUID)
    case missingTitle
    case notImplemented

    var title: String {
        switch self {
        case .cannotDeleteRoot:
            return "Failed to delete item"
        case .failedToLoadRecipes:
            return "Something went wrong"
        case .failedToSaveRecipes:
            return "Something went wrong"
        case .missingInput(_):
            return "Something went wrong"
        case .missingRecipe(_):
            return "Something went wrong"
        case .missingTitle:
            return "Missing title"
        case .notImplemented:
            return "Not implemented!"
        }
    }

    var message: String {
        switch self {
        case .cannotDeleteRoot:
            return "You cannot delete the root folder. How did you even get in this situation in the first place?"
        case .failedToLoadRecipes:
            return "Something went wrong"
        case .failedToSaveRecipes:
            return "Something went wrong"
        case .missingInput(let uuid):
            return "Missing input \(uuid)"
        case .missingRecipe(let uuid):
            return "Missing recipe \(uuid)"
        case .missingTitle:
            return "Add a title to the recipe and try again"
        case .notImplemented:
            return "This feature is not implemented. Try again later..."
        }
    }
}
