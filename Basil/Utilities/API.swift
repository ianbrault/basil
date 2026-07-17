//
//  API.swift
//  RecipeBook
//
//  Created by Ian Brault on 2/6/24.
//

import UIKit
import os

struct API {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: API.self)
    )

    enum HttpStatus {
        static let Ok = 200
    }

    private static func errorHandler<T>(_ error: any Error) -> Result<
        T, BasilError
    > {
        if Network.isOfflineError(error) {
            return .failure(.noConnection)
        } else if let basilError = error as? BasilError {
            return .failure(basilError)
        } else {
            print(error)
            return .failure(.httpError(error.localizedDescription))
        }
    }

    //
    // Generic model responses
    //

    struct FolderResponse: Codable {
        let _id: ObjectID
        let schema_version: Int
        let name: String
        let parent: ObjectID?
        let recipes: [ObjectID]
        let subfolders: [ObjectID]
    }

    struct RecipeResponse: Codable {
        let _id: ObjectID
        let schema_version: Int
        let title: String
        let parent: ObjectID
        let ingredients: [String]
        let instructions: [String]
    }

    //
    // API request/response bodies
    //

    struct AuthenticationRequest: Codable {
        let email: String
        let password: String
        let device: UUID?
    }

    struct AuthenticationResponse: Codable {
        let id: ObjectID
        let email: String
        let root: ObjectID?
        let recipes: [RecipeResponse]
        let folders: [FolderResponse]
        let token: ObjectID
    }

    struct CreateFolderRequest: Codable {
        let user_id: ObjectID
        let token_id: ObjectID
        let device: UUID?
        let uuid: ObjectID
        let name: String
        let parent: ObjectID?
    }

    struct CreateRecipeRequest: Codable {
        let user_id: ObjectID
        let token_id: ObjectID
        let device: UUID?
        let uuid: ObjectID
        let title: String
        let parent: ObjectID
        let ingredients: [String]
        let instructions: [String]
    }

    struct CreateUserRequest: Codable {
        let root: ObjectID
        let email: String
        let password: String
        let device: UUID?
    }

    struct CreateUserResponse: Codable {
        let id: ObjectID
        let email: String
        let root: ObjectID
        let token: ObjectID
    }

    struct DeleteFolderRequest: Codable {
        let user_id: ObjectID
        let token_id: ObjectID
        let device: UUID?
        let folder_id: ObjectID
    }

    struct DeleteRecipeRequest: Codable {
        let user_id: ObjectID
        let token_id: ObjectID
        let device: UUID?
        let recipe_id: ObjectID
    }

    struct DeleteUserRequest: Codable {
        let email: String
        let password: String
    }

    struct UpdateFolderRequest: Codable {
        let user_id: ObjectID
        let token_id: ObjectID
        let device: UUID?
        let folder_id: ObjectID
        let name: String
    }

    struct UpdateRecipeRequest: Codable {
        let user_id: ObjectID
        let token_id: ObjectID
        let device: UUID?
        let recipe_id: ObjectID
        let title: String
        let ingredients: [String]
        let instructions: [String]
    }

    struct UserInfo: Codable {
        let id: ObjectID
        let email: String
        let root: ObjectID?
        let recipes: [RecipeResponse]
        let folders: [FolderResponse]
        let token: ObjectID
    }

    //
    // API calls
    //

    static func authenticate(email: String, password: String) async throws
        -> UserInfo
    {
        Self.logger.info("Authenticating user \(email)")
        let request = AuthenticationRequest(
            email: email,
            password: password,
            device: StateManager.shared.device
        )
        let response: AuthenticationResponse = try await Network.post(
            url: Network.url("user/authenticate"),
            body: request
        )
        let userInfo = UserInfo(
            id: response.id,
            email: response.email,
            root: response.root,
            recipes: response.recipes,
            folders: response.folders,
            token: response.token
        )
        return userInfo
    }

    static func createFolder(_ folder: Folder) async throws -> FolderResponse {
        guard let userId = StateManager.shared.userId,
            let tokenId = StateManager.shared.tokenId,
            let device = StateManager.shared.device
        else {
            throw BasilError.missingToken
        }

        let request = CreateFolderRequest(
            user_id: userId,
            token_id: tokenId,
            device: device,
            uuid: folder.uuid,
            name: folder.name,
            parent: folder.parent
        )
        let response: FolderResponse = try await Network.post(
            url: Network.url("folder/create"),
            body: request
        )
        return response
    }

    static func createRecipe(_ recipe: Recipe) async throws -> RecipeResponse {
        guard let userId = StateManager.shared.userId,
            let tokenId = StateManager.shared.tokenId,
            let device = StateManager.shared.device
        else {
            throw BasilError.missingToken
        }

        let ingredients = recipe.ingredients.map { $0.toString() }
        let request = CreateRecipeRequest(
            user_id: userId,
            token_id: tokenId,
            device: device,
            uuid: recipe.uuid,
            title: recipe.title,
            parent: recipe.parent,
            ingredients: ingredients,
            instructions: recipe.instructions,
        )
        let response: RecipeResponse = try await Network.post(
            url: Network.url("recipe/create"),
            body: request
        )
        return response
    }

    static func createUser(
        root: ObjectID,
        email: String,
        password: String,
    ) async throws -> CreateUserResponse {
        Self.logger.info("Creating user \(email) with root \(root)")
        let request = CreateUserRequest(
            root: root,
            email: email,
            password: password,
            device: StateManager.shared.device
        )
        let response: CreateUserResponse = try await Network.post(
            url: Network.url("user/create"),
            body: request
        )
        return response
    }

    static func deleteFolder(_ folder: Folder) async throws {
        guard let userId = StateManager.shared.userId,
            let tokenId = StateManager.shared.tokenId,
            let device = StateManager.shared.device
        else {
            throw BasilError.missingToken
        }

        let request = DeleteFolderRequest(
            user_id: userId,
            token_id: tokenId,
            device: device,
            folder_id: folder.uuid,
        )
        try await Network.post(
            url: Network.url("folder/delete"),
            body: request
        )
    }

    static func deleteRecipe(_ recipe: Recipe) async throws {
        guard let userId = StateManager.shared.userId,
            let tokenId = StateManager.shared.tokenId,
            let device = StateManager.shared.device
        else {
            throw BasilError.missingToken
        }

        let request = DeleteRecipeRequest(
            user_id: userId,
            token_id: tokenId,
            device: device,
            recipe_id: recipe.uuid,
        )
        try await Network.post(
            url: Network.url("recipe/delete"),
            body: request
        )
    }

    static func deleteUser(
        email: String,
        password: String,
    ) async throws {
        Self.logger.info("Deleting user \(email)")
        let request = DeleteUserRequest(
            email: email,
            password: password,
        )
        try await Network.post(
            url: Network.url("user/delete"),
            body: request
        )
    }

    static func updateFolder(_ folder: Folder) async throws {
        guard let userId = StateManager.shared.userId,
            let tokenId = StateManager.shared.tokenId,
            let device = StateManager.shared.device
        else {
            throw BasilError.missingToken
        }

        let request = UpdateFolderRequest(
            user_id: userId,
            token_id: tokenId,
            device: device,
            folder_id: folder.uuid,
            name: folder.name,
        )
        try await Network.post(
            url: Network.url("folder/modify"),
            body: request
        )
    }

    static func updateRecipe(_ recipe: Recipe) async throws {
        guard let userId = StateManager.shared.userId,
            let tokenId = StateManager.shared.tokenId,
            let device = StateManager.shared.device
        else {
            throw BasilError.missingToken
        }

        let ingredients = recipe.ingredients.map { $0.toString() }
        let request = UpdateRecipeRequest(
            user_id: userId,
            token_id: tokenId,
            device: device,
            recipe_id: recipe.uuid,
            title: recipe.title,
            ingredients: ingredients,
            instructions: recipe.instructions,
        )
        try await Network.post(
            url: Network.url("recipe/modify"),
            body: request
        )
    }
}
