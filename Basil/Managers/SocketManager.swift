//
//  SocketManager.swift
//  Basil
//
//  Created by Ian Brault on 5/2/25.
//

import Foundation

// WebSocket API definitions

enum SocketMessageType: Int, Codable {
    case Success               = 200
    case AuthenticationRequest = 201
    case AuthenticationError   = 401
}

struct AuthenticationRequestBody: Codable {
    let userId: String
    let token: String
}

enum SocketMessage {
    case Success
    case AuthenticationRequest(AuthenticationRequestBody)
    case AuthenticationError(String)

    enum CodingKeys: String, CodingKey {
        case type
        case body
    }

    var messageType: SocketMessageType {
        switch self {
        case .Success:
            return .Success
        case .AuthenticationRequest(_):
            return .AuthenticationRequest
        case .AuthenticationError(_):
            return .AuthenticationError
        }
    }

    static func authenticationRequest(userId: String, token: String) -> SocketMessage {
        return .AuthenticationRequest(AuthenticationRequestBody(userId: userId, token: token))
    }
}

extension SocketMessage: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .Success:
            try container.encode(SocketMessageType.Success, forKey: .type)
            try container.encodeNil(forKey: .body)
        case .AuthenticationRequest(let body):
            try container.encode(SocketMessageType.AuthenticationRequest, forKey: .type)
            try container.encode(body, forKey: .body)
        case .AuthenticationError(let body):
            try container.encode(SocketMessageType.AuthenticationError, forKey: .type)
            try container.encode(body, forKey: .body)
        }
    }
}

extension SocketMessage: Decodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let type = try values.decode(SocketMessageType.self, forKey: .type)
        switch type {
        case .Success:
            self = .Success
        case .AuthenticationRequest:
            let body = try values.decode(AuthenticationRequestBody.self, forKey: .body)
            self = .AuthenticationRequest(body)
        case .AuthenticationError:
            let body = try values.decode(String.self, forKey: .body)
            self = .AuthenticationError(body)
        }
    }
}

//
// Singleton class responsible for managing WebSocket networking
//
class SocketManager: NSObject {

    protocol Delegate: AnyObject {
        func didConnectToServer()
        func didDisconnectFromServer(error: BasilError?)
        func socketError(_: BasilError)
    }

    typealias ConnectionHandler = (Result<Data, BasilError>) -> Void

    // Toggle for local development
    let socketURL = URL(string: "ws://127.0.0.1:4040/basil")!
    // let socketURL = URL(string: "wss://brault.dev/basil")!

    private var delegates: [Delegate] = []
    private var socket: URLSessionWebSocketTask? = nil
    private var token: String? = nil
    private var connected: Bool = false

    static let shared = SocketManager()

    private override init() {}

    func addDelegate(_ delegate: Delegate) {
        self.delegates.append(delegate)
    }

    func connect(token: String) {
        self.socket = URLSession.shared.webSocketTask(with: self.socketURL)
        self.token = token

        self.socket?.delegate = self
        self.socket?.resume()
    }

    func send(_ message: SocketMessage, completionHandler: @escaping (Error?) -> Void) {
        guard let socket = self.socket,
              let encoded = try? JSONEncoder().encode(message) else { return }
        socket.send(.data(encoded), completionHandler: completionHandler)
    }

    func receive(completionHandler: @escaping (Result<SocketMessage, BasilError>) -> Void) {
        guard let socket = self.socket else { return }
        socket.receive { (result) in
            switch result {
            case .success(let response):
                switch response {
                case .data(let data):
                    if let message = try? JSONDecoder().decode(SocketMessage.self, from: data) {
                        completionHandler(.success(message))
                    } else {
                        completionHandler(.failure(.socketReadError("Failed to decode message")))
                    }
                case .string(let string):
                    completionHandler(.failure(.socketReadError("Unexpected string data: \(string)")))
                @unknown default:
                    completionHandler(.failure(.socketReadError("Unexected data of unknown type")))
                }
            case .failure(let error):
                completionHandler(.failure(.socketReadError(error.localizedDescription)))
            }
        }
    }
}

extension SocketManager: URLSessionWebSocketDelegate {

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol taskProtocol: String?
    ) {
        // Socket connection established
        guard let token = self.token else { return }
        // Send the user information and token to the server for validation
        let message = SocketMessage.authenticationRequest(userId: State.manager.userId, token: token)
        self.send(message) { [weak self] (error) in
            if let error {
                for delegate in self?.delegates ?? [] {
                    delegate.socketError(.socketWriteError(error.localizedDescription))
                }
            } else {
                // Wait for the response from the server
                self?.receive { [weak self] (response) in
                    switch response {
                    case .success(let message):
                        switch message {
                        case .Success:
                            self?.connected = true
                            for delegate in self?.delegates ?? [] {
                                delegate.didConnectToServer()
                            }
                        case .AuthenticationError(let errorMessage):
                            for delegate in self?.delegates ?? [] {
                                delegate.socketError(.socketReadError(errorMessage))
                            }
                        default:
                            for delegate in self?.delegates ?? [] {
                                delegate.socketError(.socketUnexpectedMessage(message.messageType))
                            }
                        }
                    case .failure(let error):
                        for delegate in self?.delegates ?? [] {
                            delegate.socketError(error)
                        }
                    }
                }
            }
        }
    }

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        // Cancel any ongoing tasks and clear out the connection
        self.socket?.cancel()
        self.socket = nil
        self.token = nil
        self.connected = false

        // Notify the delegates
        var message = "Connection closed unexpectedly"
        if let reason, let reasonString = String(data: reason, encoding: .utf8) {
            message = reasonString
        }
        for delegate in self.delegates {
            delegate.didDisconnectFromServer(error: .socketClosed(message))
        }
    }
}
