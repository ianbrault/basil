//
//  Network.swift
//  RecipeBook
//
//  Created by Ian Brault on 9/3/23.
//

import Foundation

func httpStatusIsError(_ status: Int) -> Bool {
    return status < 200 || status >= 300
}

func httpGet(url: String, handler: @escaping (Result<Data, RBError>) -> ()) {
    guard let url = URL(string: url) else {
        handler(.failure(.invalidURL(url)))
        return
    }

    let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
        if let error {
            handler(.failure(.httpError(error.localizedDescription)))
            return
        }
        if let httpResponse = response as? HTTPURLResponse {
            if httpStatusIsError(httpResponse.statusCode) {
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

func httpPost(url: String, body: [String: Any], handler: @escaping (Result<Data, RBError>) -> ()) {
    guard let url = URL(string: url) else {
        handler(.failure(.invalidURL(url)))
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
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
            if httpStatusIsError(httpResponse.statusCode) {
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
