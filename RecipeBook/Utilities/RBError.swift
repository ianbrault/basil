//
//  RBError.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/6/23.
//

import Foundation

enum RBError: Error {
    case cannotModifyRoot
    case failedToDecode
    case failedToEncode
    case failedToLoadRecipes
    case failedToParseRecipe(String?)
    case failedToSaveRecipes
    case httpError(String)
    case invalidURL(String)
    case missingHTTPData
    case missingInput(UUID)
    case missingRecipe(UUID)
    case missingTitle
    case notImplemented
    case passwordsDoNotMatch

    var title: String {
        switch self {
        case .httpError(_):
            return "An error occurred"
        case .invalidURL(_):
            return "Invalid URL"
        case .missingTitle:
            return "Missing title"
        case .notImplemented:
            return "Not implemented!"
        case .passwordsDoNotMatch:
            return "Passwords do not Match"
        case .cannotModifyRoot,
             .failedToDecode,
             .failedToEncode,
             .failedToLoadRecipes,
             .failedToParseRecipe(_),
             .failedToSaveRecipes,
             .missingHTTPData,
             .missingInput(_),
             .missingRecipe(_):
            return "Something went wrong"
        }
    }

    var message: String {
        switch self {
        case .cannotModifyRoot:
            return "You cannot modify the root folder. How did you even get in this situation in the first place?"
        case .failedToDecode:
            return "Invalid UTF-8 response body"
        case .failedToEncode:
            return "Failed to encode string"
        case .failedToLoadRecipes,
             .failedToSaveRecipes:
            return "Something went wrong"
        case .failedToParseRecipe(let message):
            return message ?? "Error while parsing recipe"
        case .httpError(let error):
            return error
        case .invalidURL(let string):
            return string
        case .missingHTTPData:
            return "Empty response body"
        case .missingInput(let uuid):
            return "Missing input \(uuid)"
        case .missingRecipe(let uuid):
            return "Missing recipe \(uuid)"
        case .missingTitle:
            return "Add a title to the recipe and try again"
        case .notImplemented:
            return "This feature is not implemented. Try again later..."
        case .passwordsDoNotMatch:
            return "Re-enter your password and try again"
        }
    }
}
