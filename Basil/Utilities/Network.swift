//
//  Network.swift
//  RecipeBook
//
//  Created by Ian Brault on 9/3/23.
//

import Foundation

//
// Wrapper struct containing networking functions as static members
//
struct Network {

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

    static func get(url: URL, handler: @escaping (Result<Data, BasilError>) -> ()) {
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

    static func post<T: Encodable>(_ string: String, body: T, handler: @escaping (Result<Data?, BasilError>) -> ()) {
        guard let url = URL(string: string) else {
            handler(.failure(.invalidURL(string)))
            return
        }
        self.post(url: url, body: body, handler: handler)
    }
}
