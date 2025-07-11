//
//  NetworkManager.swift
//  Basil
//
//  Created by Ian Brault on 5/11/25.
//

import Foundation

//
// Singleton class responsible for managing network requests and responses
//
class NetworkManager {

    typealias Handler = (BasilError?) -> ()
    typealias BodyHandler<T> = (Result<T, BasilError>) -> ()

    // static let baseURL = URL(string: "http://localhost:3030/basil/v2")!
    // static let baseURL = URL(string: "http://brault.dev/nightly/basil/v2")!
    static let baseURL = URL(string: "https://brault.dev/basil/v2")!

    private init() {}

    private static func statusIsError(_ status: Int) -> Bool {
        return status < 200 || status >= 300
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

    static func get(url: URL, handler: @escaping (Result<Data, BasilError>) -> ()) {
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            if let error {
                handler(.failure(.httpError(error.localizedDescription)))
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                if self.statusIsError(httpResponse.statusCode) {
                    var message = "Invalid response(\(httpResponse.statusCode))"
                    if let data {
                        if let errorMessage = String(data: data, encoding: .utf8) {
                            message = errorMessage
                        }
                    }
                    handler(.failure(.httpError(message)))
                    return
                }
            }
            if let data {
                handler(.success(data))
            } else {
                handler(.failure(.httpError("Missing response data")))
            }
        }
        task.resume()
    }

    static func get(string: String, handler: @escaping (Result<Data, BasilError>) -> ()) {
        guard let url = URL(string: string) else {
            handler(.failure(.invalidURL(string)))
            return
        }
        self.get(url: url, handler: handler)
    }

    static func post<T: Encodable>(url: URL, body: T, handler: @escaping (Result<Data?, BasilError>) -> ()) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            handler(.failure(.encodeError))
            return
        }

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error {
                handler(.failure(.httpError(error.localizedDescription)))
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                if self.statusIsError(httpResponse.statusCode) {
                    var message = "Invalid response(\(httpResponse.statusCode))"
                    if let data {
                        if let errorMessage = String(data: data, encoding: .utf8) {
                            message = errorMessage
                        }
                    }
                    handler(.failure(.httpError(message)))
                    return
                }
            }
            handler(.success(data))
        }
        task.resume()
    }

    static func post<T: Encodable>(_ string: String, body: T, handler: @escaping (Result<Data?, BasilError>) -> ()) {
        guard let url = URL(string: string) else {
            handler(.failure(.invalidURL(string)))
            return
        }
        self.post(url: url, body: body, handler: handler)
    }

    // API calls

    static func authenticate(
        email: String, password: String,
        handler: @escaping BodyHandler<API.AuthenticationResponse>
    ) {
        let body = API.AuthenticationRequest(email: email, password: password, device: State.manager.deviceToken)
        self.post(url: self.baseURL.appending(path: "user/authenticate"), body: body) { (response) in
            let result: Result<API.AuthenticationResponse, BasilError> = response.flatMap(self.parseResponse)
            handler(result)
        }
    }

    static func createUser(
        email: String, password: String, root: UUID?, recipes: [Recipe], folders: [RecipeFolder],
        handler: @escaping BodyHandler<API.AuthenticationResponse>
    ) {
        let body = API.CreateUserRequest(
            email: email, password: password,
            root: root, recipes: recipes, folders: folders,
            device: State.manager.deviceToken
        )
        self.post(url: self.baseURL.appending(path: "user/create"), body: body) { (response) in
            let result: Result<API.AuthenticationResponse, BasilError> = response.flatMap(self.parseResponse)
            handler(result)
        }
    }

    static func deleteUser(email: String, password: String, handler: @escaping Handler) {
        let body = API.AuthenticationRequest(email: email, password: password, device: nil)
        self.post(url: self.baseURL.appending(path: "user/delete"), body: body) { (response) in
            switch response {
            case .success(_):
                handler(nil)
            case .failure(let error):
                handler(error)
            }
        }
    }

    static func pushUpdate(
        userId: String, token: String, root: UUID?, recipes: [Recipe], folders: [RecipeFolder],
        handler: @escaping Handler
    ) {
        let body = API.PushUpdateRequest(userId: userId, token: token, root: root, recipes: recipes, folders: folders)
        self.post(url: self.baseURL.appending(path: "user/update"), body: body) { (response) in
            switch response {
            case .success(_):
                handler(nil)
            case .failure(let error):
                handler(error)
            }
        }
    }
}
