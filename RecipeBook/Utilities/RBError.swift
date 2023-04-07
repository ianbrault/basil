//
//  RBError.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/6/23.
//

import Foundation

enum RBError: Error {
    case failedToLoadRecipes
    case failedToSaveRecipes
    case missingInput(UUID)
    case missingTitle

    var title: String {
        switch self {
        case .failedToLoadRecipes:
            return "Something went wrong"
        case .failedToSaveRecipes:
            return "Something went wrong"
        case .missingInput(_):
            return "Something went wrong"
        case .missingTitle:
            return "Missing title"
        }
    }

    var message: String {
        switch self {
        case .failedToLoadRecipes:
            return "Something went wrong"
        case .failedToSaveRecipes:
            return "Something went wrong"
        case .missingInput(let uuid):
            return "Missing input \(uuid)"
        case .missingTitle:
            return "Add a title to the recipe and try again"
        }
    }
}
