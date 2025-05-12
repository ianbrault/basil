//
//  RBError.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/6/23.
//

import Foundation

enum BasilError: Error {
    case cannotModifyRoot
    case decodeError
    case encodeError
    case httpError(String)
    case invalidConversion(Unit, Unit)
    case invalidURL(String)
    case keychainError(String)
    case missingItem(State.Item, UUID)
    case missingTitle
    case noConnection
    case notImplemented
    case passwordsDoNotMatch
    case readOnly(String, State.Item)
    case recipeParseError(String?)
    case socketClosed(String)
    case socketReadError(String)
    case socketWriteError(String)
    case socketUnexpectedMessage(SocketMessageType)

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
        case .readOnly(let action, let itemType):
            switch itemType {
            case .recipe:
                return "Cannot \(action) recipe"
            case .folder:
                return "Missing \(action) folder"
            }
        case .socketClosed(_):
            return "Lost connection to the server"
        case .socketReadError(_),
             .socketWriteError(_):
            return "Failed to communicate with the server"
        case .cannotModifyRoot,
             .decodeError,
             .encodeError,
             .keychainError(_),
             .missingItem(_, _),
             .recipeParseError(_),
             .socketUnexpectedMessage(_):
            return "Something went wrong"
        }
    }

    var message: String {
        switch self {
        case .cannotModifyRoot:
            return "You cannot modify the root folder. How did you even get in this situation in the first place?"
        case .decodeError:
            return "Failed to decode string"
        case .encodeError:
            return "Failed to encode string"
        case .keychainError(let message):
            return "Keychain storage failure: \(message)"
        case .httpError(let error):
            return error
        case .invalidConversion(let from, let to):
            return "Cannot convert from \(from.toString()) to \(to.toString())"
        case .invalidURL(let string):
            return string
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
            return "You will not be able to make changes until you are back online"
        case .notImplemented:
            return "This feature is not implemented. Try again later..."
        case .passwordsDoNotMatch:
            return "Re-enter your password and try again"
        case .readOnly(_, _):
            return "Cannot make changes to recipes or folders while offline in read-only mode"
        case .recipeParseError(let message):
            return message ?? "An error occurred while parsing the recipe"
        case .socketClosed(let message),
             .socketReadError(let message),
             .socketWriteError(let message):
            return message
        case .socketUnexpectedMessage(let type):
            return "Unexpected socket message of type \(type)"
        }
    }
}
