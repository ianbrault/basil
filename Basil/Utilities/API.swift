//
//  API.swift
//  RecipeBook
//
//  Created by Ian Brault on 2/6/24.
//

import UIKit

struct API {

    typealias Handler = (RBError?) -> ()
    typealias BodyHandler<T> = (Result<T, RBError>) -> ()

    struct UserInfo: Codable {
        let id: String
        let email: String
        let key: UUID?
        let root: UUID?
        let recipes: [Recipe]
        let folders: [RecipeFolder]
    }

    struct UserInfoBasic: Codable {
        let id: String
        let key: UUID?
    }

    struct UserLoginInfo: Codable {
        let email: String
        let password: String
    }

    struct UserRegisterInfo: Codable {
        let email: String
        let password: String
        let root: UUID?
        let recipes: [Recipe]
        let folders: [RecipeFolder]
    }

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

    static func pokeServer(handler: @escaping Handler) {
        let body = UserInfoBasic(id: State.manager.userId, key: State.manager.userKey)
        DispatchQueue.global(qos: .userInitiated).async {
            Network.post(.poke, body: body) { (response) in
                switch response {
                case .success(_):
                    handler(nil)
                case .failure(let error):
                    handler(error)
                }
            }
        }
    }

    static func login(email: String, password: String, handler: @escaping BodyHandler<UserInfo>) {
        let body = UserLoginInfo(email: email, password: password)
        Network.post(.login, body: body) { (response) in
            let result: Result<UserInfo, RBError> = response.flatMap(self.parseResponse)
            handler(result)
        }
    }

    static func register(
        email: String, password: String, root: UUID?, recipes: [Recipe], folders: [RecipeFolder],
        handler: @escaping BodyHandler<UserInfo>
    ) {
        let body = UserRegisterInfo(email: email, password: password, root: root, recipes: recipes, folders: folders)
        Network.post(.register, body: body) { (response) in
            let result: Result<UserInfo, RBError> = response.flatMap(self.parseResponse)
            handler(result)
        }
    }

    static func updateUser(async: Bool = false, handler: Handler? = nil) {
        let body = UserInfo(
            id: State.manager.userId, email: State.manager.userEmail, key: State.manager.userKey,
            root: State.manager.root, recipes: State.manager.recipes, folders: State.manager.folders
        )
        self.call(.update, body: body, async: async, handler: handler)
    }
}
