//
//  Network.swift
//  Basil
//
//  Created by Ian Brault on 5/11/25.
//

import Foundation
import os

struct Network {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Network.self)
    )

    // static let baseURL = URL(string: "https://brault.dev/basil/v2")!
    // FIXME: DEBUG
    static let baseURL = URL(string: "http://localhost:4000/basil/v2")!

    static func url(_ path: String) -> URL {
        return baseURL.appending(path: path)
    }

    private static func statusIsError(_ status: Int) -> Bool {
        return status < 200 || status >= 300
    }

    private static func checkResponse(data: Data, response: URLResponse) throws
    {
        if let httpResponse = response as? HTTPURLResponse {
            if Self.statusIsError(httpResponse.statusCode) {
                Self.logger.warning(
                    "HTTP call failed with status \(httpResponse.statusCode)"
                )
                if let errorMessage = String(
                    data: data,
                    encoding: .utf8
                ) {
                    Self.logger.warning("HTTP error message: \(errorMessage)")
                    throw BasilError.httpError(errorMessage)
                } else {
                    throw
                        BasilError.httpError(
                            "Invalid response with status \(httpResponse.statusCode)"
                        )
                }
            }
        }
    }

    static func get(url: URL) async throws -> Data {
        Self.logger.debug("GET: \(url)")

        let (data, response) = try await URLSession.shared.data(from: url)
        try Self.checkResponse(data: data, response: response)
        return data
    }

    static func get(string: String) async throws -> Data {
        guard let url = URL(string: string) else {
            throw BasilError.invalidURL(string)
        }
        return try await Self.get(url: url)
    }

    static func post<Request: Encodable, Response: Decodable>(
        url: URL,
        body: Request,
    ) async throws -> Response {
        Self.logger.debug("POST: \(url)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.checkResponse(data: data, response: response)
        return try JSONDecoder().decode(Response.self, from: data)
    }

    static func post<Request: Encodable>(
        url: URL,
        body: Request,
    ) async throws {
        Self.logger.debug("POST: \(url)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.checkResponse(data: data, response: response)
    }

    static func isOfflineError(_ error: any Error) -> Bool {
        guard let error = error as? URLError else { return false }
        switch error.code {
        case .cannotConnectToHost, .networkConnectionLost,
            .notConnectedToInternet, .timedOut:
            return true
        default:
            return false
        }
    }
}
