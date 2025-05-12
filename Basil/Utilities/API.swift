//
//  API.swift
//  RecipeBook
//
//  Created by Ian Brault on 2/6/24.
//

import UIKit

struct API {

    // Network API definitions

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

    // Socket API definitions

    enum SocketMessageType: Int, Codable {
        case Success               = 200
        case AuthenticationRequest = 201
        case AuthenticationError   = 401
    }

    struct AuthenticationRequestBody: Codable {
        let userId: String
        let token: String
    }

    enum SocketMessage: Decodable, Encodable {
        case Success
        case AuthenticationRequest(AuthenticationRequestBody)
        case AuthenticationError(String)

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
            case .AuthenticationError(_):
                return .AuthenticationError
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
            case .AuthenticationError:
                let body = try values.decode(String.self, forKey: .body)
                self = .AuthenticationError(body)
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
            case .AuthenticationError(let body):
                try container.encode(SocketMessageType.AuthenticationError, forKey: .type)
                try container.encode(body, forKey: .body)
            }
        }

        static func authenticationRequest(userId: String, token: String) -> SocketMessage {
            return .AuthenticationRequest(AuthenticationRequestBody(userId: userId, token: token))
        }
    }
}
