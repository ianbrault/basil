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
    case invalidConversion(Unit, Unit)
    case invalidURL(String)
    case missingHTTPData
    case missingInput(UUID)
    case missingItem(State.Item, UUID)
    case missingTitle
    case noConnection
    case notImplemented
    case passwordsDoNotMatch

    var title: String {
        switch self {
        case .httpError(_):
            return "An error occurred"
        case .invalidConversion(_, _):
            return "Invalid unit conversion"
        case .invalidURL(_):
            return "Invalid URL"
        case .missingTitle:
            return "Missing title"
        case .notImplemented:
            return "Not implemented!"
        case .passwordsDoNotMatch:
            return "Passwords do not Match"
        case .noConnection:
            return "Could not reach server"
        case .cannotModifyRoot,
             .failedToDecode,
             .failedToEncode,
             .failedToLoadRecipes,
             .failedToParseRecipe(_),
             .failedToSaveRecipes,
             .missingHTTPData,
             .missingInput(_),
             .missingItem(_, _):
            return "Something went wrong"
        }
    }

    var message: String {
        switch self {
        case .cannotModifyRoot:
            return "You cannot modify the root folder. How did you even get in this situation in the first place?"
        case .failedToDecode:
            return "Failed to decode string"
        case .failedToEncode:
            return "Failed to encode string"
        case .failedToLoadRecipes,
             .failedToSaveRecipes:
            return "Something went wrong"
        case .failedToParseRecipe(let message):
            return message ?? "Error while parsing recipe"
        case .httpError(let error):
            return error
        case .invalidConversion(let from, let to):
            return "Cannot convert from \(from.toString()) to \(to.toString())"
        case .invalidURL(let string):
            return string
        case .missingHTTPData:
            return "Empty response body"
        case .missingInput(let uuid):
            return "Missing input \(uuid)"
        case .missingItem(let itemType, let uuid):
            switch itemType {
            case .recipe:
                return "Missing recipe \(uuid)"
            case .folder:
                return "Missing folder \(uuid)"
            }
        case .missingTitle:
            return "Add a title to the recipe and try again"
        case .noConnection:
            return "Changes will not be saved to the server until you are back online"
        case .notImplemented:
            return "This feature is not implemented. Try again later..."
        case .passwordsDoNotMatch:
            return "Re-enter your password and try again"
        }
    }
}
