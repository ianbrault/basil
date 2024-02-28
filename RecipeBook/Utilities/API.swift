//
//  API.swift
//  RecipeBook
//
//  Created by Ian Brault on 2/6/24.
//

import UIKit

struct UserInfoBody: Codable {
    let userId: String
    let userKey: UUID?
}

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

struct RecipesFoldersUUIDBody: Codable {
    let userId: String
    let userKey: UUID?
    let recipes: [UUID]
    let folders: [UUID]
}

struct API {

    typealias Handler = (RBError?) -> ()
    typealias BodyHandler<T> = (Result<T, RBError>) -> ()

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

    static private func _call<T: Encodable>(_ address: Network.Address, body: T, async: Bool = false, handler: Handler? = nil) {
        Network.post(address, body: body) { (response) in
            guard let handler else { return }
            switch response {
            case .success(_):
                handler(nil)
            case .failure(let error):
                handler(error)
            }
        }
    }

    static func call<T: Encodable>(_ address: Network.Address, body: T, async: Bool = false, handler: Handler? = nil) {
        if async {
            DispatchQueue.global(qos: .userInitiated).async {
                self._call(address, body: body, async: async, handler: handler)
            }
        } else {
            self._call(address, body: body, async: async, handler: handler)
        }
    }

    /*
    static func asyncCall<T: Encodable>(_ address: Network.Address, body: T, handler: Handler? = nil) {
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
    */

    static func pokeServer(handler: @escaping Handler) {
        let body = UserInfoBody(userId: State.manager.userId, userKey: State.manager.userKey)
        Network.post(.poke, body: body) { (response) in
            switch response {
            case .success(_):
                handler(nil)
            case .failure(let error):
                handler(error)
            }
        }
    }

    static func login(email: String, password: String, handler: @escaping BodyHandler<UserLoginResponse>) {
        let body = UserLoginBody(email: email, password: password)
        Network.post(.login, body: body) { (response) in
            let result: Result<UserLoginResponse, RBError> = response.flatMap(self.parseResponse)
            handler(result)
        }
    }

    static func register(email: String, password: String, handler: @escaping BodyHandler<UserLoginResponse>) {
        let body = UserLoginBody(email: email, password: password)
        Network.post(.register, body: body) { (response) in
            let result: Result<UserLoginResponse, RBError> = response.flatMap(self.parseResponse)
            handler(result)
        }
    }

    static func createItem(recipe: Recipe? = nil, folder: RecipeFolder? = nil, async: Bool = false, handler: Handler? = nil) {
        let body = RecipeFolderBody(
            userId: State.manager.userId, userKey: State.manager.userKey, 
            recipe: recipe, folder: folder
        )
        self.call(.create, body: body, async: async, handler: handler)
    }

    static func updateItems(recipes: [Recipe] = [], folders: [RecipeFolder] = [], async: Bool = false, handler: Handler? = nil) {
        let body = RecipesFoldersBody(
            userId: State.manager.userId, userKey: State.manager.userKey,
            recipes: recipes, folders: folders
        )
        self.call(.update, body: body, async: async, handler: handler)
    }

    static func deleteItems(recipes: [UUID] = [], folders: [UUID] = [], async: Bool = false, handler: Handler? = nil) {
        let body = RecipesFoldersUUIDBody(
            userId: State.manager.userId, userKey: State.manager.userKey,
            recipes: recipes, folders: folders
        )
        self.call(.delete, body: body, async: async, handler: handler)
    }
}
