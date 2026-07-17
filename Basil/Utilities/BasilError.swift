//
//  BasilError.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/6/23.
//

import Foundation

enum BasilError: Error, Equatable {

    case cannotModifyRoot
    case decodeError
    case encodeError
    case extensionError(String)
    case httpError(String)
    case invalidConversion(Unit, Unit)
    case invalidURL(String)
    case keychainError(OSStatus)
    case missingFolder(ObjectID?)
    case missingItem(ObjectID)
    case missingTitle
    case missingToken
    case noConnection
    case offlineQueueFull
    case passwordsDoNotMatch
    case recipeParseError(String?)
    case resourceNotFound(String)

    var message: String {
        switch self {
        case .extensionError(let message),
            .httpError(let message),
            .invalidURL(let message):
            return message
        case .cannotModifyRoot:
            return
                "You cannot modify the root folder. How did you even get in this situation in the first place?"
        case .decodeError:
            return "Failed to decode string"
        case .encodeError:
            return "Failed to encode string"
        case .keychainError(let status):
            let statusMessage =
                SecCopyErrorMessageString(status, nil) as? String ?? "unknown"
            return "Keychain failure: \(statusMessage)"
        case .invalidConversion(let from, let to):
            return "Cannot convert from \(from.toString()) to \(to.toString())"
        case .missingFolder(let uuid):
            return "Missing folder with ID \(uuid?.description ?? "nil")"
        case .missingItem(let uuid):
            return "Missing item with ID \(uuid)"
        case .missingTitle:
            return "Add a title to the recipe and try again"
        case .missingToken:
            return "Missing user token, try logging in again."
        case .noConnection:
            return "Try again later."
        case .offlineQueueFull:
            return
                "The offline action queue is full. Connect to the server and try again."
        case .passwordsDoNotMatch:
            return "Re-enter your password and try again"
        case .recipeParseError(let message):
            return message ?? "An error occurred while parsing the recipe"
        case .resourceNotFound(let name):
            return "Missing resource \"\(name)\""
        }
    }
}
