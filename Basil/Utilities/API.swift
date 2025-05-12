//
//  API.swift
//  RecipeBook
//
//  Created by Ian Brault on 2/6/24.
//

import UIKit

struct API {

    static let baseURL = "http://localhost:3030/basil/v2"
    // static let baseURL = "https://brault.dev/basil/v2"

    typealias Handler = (BasilError?) -> ()
    typealias BodyHandler<T> = (Result<T, BasilError>) -> ()

    // Web API definitions

    struct UserInfo: Codable {
        let id: String
        let email: String
        let root: UUID?
        let recipes: [Recipe]
        let folders: [RecipeFolder]
        let token: String
    }

    struct UserDeleteInfo: Codable {
        let email: String
        let password: String
    }

    struct UserAuthInfo: Codable {
        let email: String
        let password: String
        let device: UUID?
    }

    struct UserRegisterInfo: Codable {
        let email: String
        let password: String
        let root: UUID?
        let recipes: [Recipe]
        let folders: [RecipeFolder]
        let device: UUID?
    }

    // Functions

    static func url(_ path: String) -> URL {
        return URL(string: "\(self.baseURL)/\(path)")!
    }

    static func parseResponse<T: Decodable>(body contents: Data?) -> Result<T, BasilError> {
        guard let contents else {
            return .failure(.httpError("Missing response data"))
        }
        do {
            let userInfo = try JSONDecoder().decode(T.self, from: contents)
            return .success(userInfo)
        } catch {
            return .failure(.decodeError)
        }
    }

    static func register(
        email: String, password: String, root: UUID?, recipes: [Recipe], folders: [RecipeFolder],
        handler: @escaping BodyHandler<UserInfo>
    ) {
        let body = UserRegisterInfo(
            email: email, password: password,
            root: root, recipes: recipes, folders: folders,
            device: State.manager.deviceToken
        )
        Network.post(url: self.url("user/create"), body: body) { (response) in
            let result: Result<UserInfo, BasilError> = response.flatMap(self.parseResponse)
            handler(result)
        }
    }

    static func authenticate(email: String, password: String, handler: @escaping BodyHandler<UserInfo>) {
        let body = UserAuthInfo(email: email, password: password, device: State.manager.deviceToken)
        Network.post(url: self.url("user/authenticate"), body: body) { (response) in
            let result: Result<UserInfo, BasilError> = response.flatMap(self.parseResponse)
            handler(result)
        }
    }

    static func deleteUser(email: String, password: String, handler: @escaping Handler) {
        let body = UserDeleteInfo(email: email, password: password)
        Network.post(url: self.url("user/delete"), body: body) { (response) in
            switch response {
            case .success(_):
                handler(nil)
            case .failure(let error):
                handler(error)
            }
        }
    }
}
