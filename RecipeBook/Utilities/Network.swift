//
//  Network.swift
//  RecipeBook
//
//  Created by Ian Brault on 9/3/23.
//

import Foundation

func HTTPGet(url: String, handler: @escaping (Result<String, RBError>) -> ()) {
    if let url = URL(string: url) {
        let task = URLSession.shared.dataTask(with: url) {(data, _, error) in
            if let error {
                handler(.failure(.httpError(error)))
                return
            }
            if let data {
                if let body = String(data: data, encoding: .utf8) {
                    handler(.success(body))
                } else {
                    handler(.failure(.failedToDecode))
                }
            } else {
                handler(.failure(.missingHTTPData))
            }
        }
        task.resume()
    } else {
        handler(.failure(.invalidURL(url)))
    }
}
