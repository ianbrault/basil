//
//  Network.swift
//  RecipeBook
//
//  Created by Ian Brault on 9/3/23.
//

import Foundation

struct Network {

    enum Address {
        case login
        case poke
        case register
        case update

        var url: URL {
            // let baseURL = "http://127.0.0.1:3030"
            let baseURL = "https://brault.dev"
            switch self {
            case .login:
                return URL(string: "\(baseURL)/recipes/login")!
            case .poke:
                return URL(string: "\(baseURL)/recipes/user/poke")!
            case .register:
                return URL(string: "\(baseURL)/recipes/register")!
            case .update:
                return URL(string: "\(baseURL)/recipes/user/update")!
            }
        }
    }

    static func statusIsError(_ status: Int) -> Bool {
        return status < 200 || status >= 300
    }

    static func encode<T: Encodable>(_ item: T) -> String? {
        do {
            let data = try JSONEncoder().encode(item)
            if let string = String(data: data, encoding: .utf8) {
                return string
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }

    static func get(_ urlString: String, handler: @escaping (Result<Data, RBError>) -> ()) {
        guard let url = URL(string: urlString) else {
            handler(.failure(.invalidURL(urlString)))
            return
        }
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            if let error {
                handler(.failure(.httpError(error.localizedDescription)))
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                if Network.statusIsError(httpResponse.statusCode) {
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
                handler(.failure(.missingHTTPData))
            }
        }
        task.resume()
    }

    static func post<T: Encodable>(_ address: Address, body: T, handler: @escaping (Result<Data?, RBError>) -> ()) {
        var request = URLRequest(url: address.url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            handler(.failure(.failedToEncode))
            return
        }

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error {
                handler(.failure(.httpError(error.localizedDescription)))
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                if Network.statusIsError(httpResponse.statusCode) {
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
}
