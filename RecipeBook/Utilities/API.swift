//
//  API.swift
//  RecipeBook
//
//  Created by Ian Brault on 2/6/24.
//

import UIKit

struct UserLoginBody: Codable {
    let email: String
    let password: String
}

struct UserLoginResponse: Codable {
    let id: String
    let key: UUID
    let root: UUID?
    let recipes: [Recipe]
    let folders: [RecipeFolder]
}

struct RecipeFolderBody: Codable {
    let userId: String
    let userKey: UUID?
    let recipe: Recipe?
    let folder: RecipeFolder?
}

struct RecipesFoldersBody: Codable {
    let userId: String
    let userKey: UUID?
    let recipes: [Recipe]
    let folders: [RecipeFolder]
}

struct API {

    static func parseResponse<T: Decodable>(body contents: Data?) -> Result<T, RBError> {
        guard let contents else {
            return .failure(.missingHTTPData)
        }

        do {
            let userInfo = try JSONDecoder().decode(T.self, from: contents)
            return .success(userInfo)
        } catch {
            return .failure(.failedToDecode)
        }
    }

    static func asyncCall<T: Encodable>(_ address: Network.Address, body: T) {
        DispatchQueue.global(qos: .userInitiated).async {
            Network.post(address, body: body) { (response) in
                switch response {
                case .success(_):
                    return
                case .failure(let error):
                    DispatchQueue.main.async {
                        // use the global window to present errors
                        let window = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.last
                        window?.rootViewController?.presentErrorAlert(error)
                    }
                }
            }
        }
    }

    static func login(email: String, password: String, handler: @escaping (Result<UserLoginResponse, RBError>) -> ()) {
        let body = UserLoginBody(email: email, password: password)
        Network.post(.login, body: body) { (response) in
            let result: Result<UserLoginResponse, RBError> = response.flatMap(self.parseResponse)
            handler(result)
        }
    }

    static func register(email: String, password: String, handler: @escaping (Result<UserLoginResponse, RBError>) -> ()) {
        let body = UserLoginBody(email: email, password: password)
        Network.post(.register, body: body) { (response) in
            let result: Result<UserLoginResponse, RBError> = response.flatMap(self.parseResponse)
            handler(result)
        }
    }

    static func createItem(recipe: Recipe? = nil, folder: RecipeFolder? = nil) {
        let body = RecipeFolderBody(
            userId: State.manager.userId, userKey: State.manager.userKey, 
            recipe: recipe, folder: folder
        )
        self.asyncCall(.create, body: body)
    }

    static func updateItems(recipes: [Recipe] = [], folders: [RecipeFolder] = []) {
        let body = RecipesFoldersBody(
            userId: State.manager.userId, userKey: State.manager.userKey,
            recipes: recipes, folders: folders
        )
        self.asyncCall(.update, body: body)
    }
}
