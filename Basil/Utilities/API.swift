//
//  API.swift
//  RecipeBook
//
//  Created by Ian Brault on 2/6/24.
//

import UIKit

struct API {

    //
    // Network API definitions
    //

    struct AuthenticationRequest: Codable {
        let email: String
        let password: String
        let device: UUID?
    }

    struct AuthenticationResponse: Codable {
        let id: String
        let email: String
        let root: UUID?
        let recipes: [Recipe]
        let folders: [RecipeFolder]
        let sequence: Int
        let token: String
    }

    struct CreateUserRequest: Codable {
        let email: String
        let password: String
        let root: UUID?
        let recipes: [Recipe]
        let folders: [RecipeFolder]
        let device: UUID?
    }

    struct PushUpdateRequest: Codable {
        let userId: String
        let token: String
        let root: UUID?
        let recipes: [Recipe]
        let folders: [RecipeFolder]
    }

    //
    // Socket API definitions
    //

    enum SocketMessageType: Int, Codable {
        case Success               = 200
        case AuthenticationRequest = 201
        case UpdateRequest         = 202
        case SyncRequest           = 203
        case AuthenticationError   = 401
        case UpdateError           = 402
    }

    struct AuthenticationRequestBody: Codable {
        let userId: String
        let token: String
    }

    struct UpdateRequestBody: Codable {
        let root: UUID?
        let recipes: [Recipe]
        let folders: [RecipeFolder]
    }

    struct SyncRequestBody: Codable {
        let root: UUID?
        let recipes: [Recipe]
        let folders: [RecipeFolder]
        let sequence: Int
    }

    enum SocketMessage: Decodable, Encodable {
        case Success
        case AuthenticationRequest(AuthenticationRequestBody)
        case UpdateRequest(UpdateRequestBody)
        case SyncRequest(SyncRequestBody)
        case AuthenticationError(String)
        case UpdateError(String)

        enum CodingKeys: String, CodingKey {
            case type
            case body
        }

        var messageType: SocketMessageType {
            switch self {
            case .Success:
                return .Success
            case .AuthenticationRequest(_):
                return .AuthenticationRequest
            case .UpdateRequest(_):
                return .UpdateRequest
            case .SyncRequest(_):
                return .SyncRequest
            case .AuthenticationError(_):
                return .AuthenticationError
            case .UpdateError(_):
                return .UpdateError
            }
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let type = try values.decode(SocketMessageType.self, forKey: .type)
            switch type {
            case .Success:
                self = .Success
            case .AuthenticationRequest:
                let body = try values.decode(AuthenticationRequestBody.self, forKey: .body)
                self = .AuthenticationRequest(body)
            case .UpdateRequest:
                let body = try values.decode(UpdateRequestBody.self, forKey: .body)
                self = .UpdateRequest(body)
            case .SyncRequest:
                let body = try values.decode(SyncRequestBody.self, forKey: .body)
                self = .SyncRequest(body)
            case .AuthenticationError:
                let body = try values.decode(String.self, forKey: .body)
                self = .AuthenticationError(body)
            case .UpdateError:
                let body = try values.decode(String.self, forKey: .body)
                self = .UpdateError(body)
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .Success:
                try container.encode(SocketMessageType.Success, forKey: .type)
                try container.encodeNil(forKey: .body)
            case .AuthenticationRequest(let body):
                try container.encode(SocketMessageType.AuthenticationRequest, forKey: .type)
                try container.encode(body, forKey: .body)
            case .UpdateRequest(let body):
                try container.encode(SocketMessageType.UpdateRequest, forKey: .type)
                try container.encode(body, forKey: .body)
            case .SyncRequest(let body):
                try container.encode(SocketMessageType.SyncRequest, forKey: .type)
                try container.encode(body, forKey: .body)
            case .AuthenticationError(let body):
                try container.encode(SocketMessageType.AuthenticationError, forKey: .type)
                try container.encode(body, forKey: .body)
            case .UpdateError(let body):
                try container.encode(SocketMessageType.UpdateError, forKey: .type)
                try container.encode(body, forKey: .body)
            }
        }

        static func authenticationRequest(userId: String, token: String) -> Self {
            return .AuthenticationRequest(AuthenticationRequestBody(userId: userId, token: token))
        }

        static func updateRequest(root: UUID?, recipes: [Recipe], folders: [RecipeFolder]) -> Self {
            return .UpdateRequest(UpdateRequestBody(root: root, recipes: recipes, folders: folders))
        }
    }
}
