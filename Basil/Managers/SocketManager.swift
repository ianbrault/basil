//
//  SocketManager.swift
//  Basil
//
//  Created by Ian Brault on 5/2/25.
//

import Foundation

//
// Singleton class responsible for managing WebSocket networking
//
class SocketManager: NSObject {

    protocol Delegate: AnyObject {
        func didConnectToServer()
        func socketError(_: BasilError)
    }

    // Toggle for local development
    let socketURL = URL(string: "ws://localhost:4040/basil")!
    // let socketURL = URL(string: "wss://brault.dev/basil")!

    private var delegates: [Delegate] = []
    private var socket: URLSessionWebSocketTask? = nil
    private var userId: String? = nil
    private var token: String? = nil
    private var connected: Bool = false
    private var clientDisconnect: Bool = false

    static let shared = SocketManager()

    private override init() {}

    func addDelegate(_ delegate: Delegate) {
        self.delegates.append(delegate)
    }

    func connect(userId: String, token: String) {
        self.socket = URLSession.shared.webSocketTask(with: self.socketURL)
        self.userId = userId
        self.token = token
        self.clientDisconnect = false

        self.socket?.delegate = self
        self.socket?.resume()
    }

    func disconnect() {
        // signal to the didCloseWith delegate method that we initiated this disconnect
        self.clientDisconnect = true

        self.socket?.cancel(with: .goingAway, reason: nil)
        self.socket = nil
        self.userId = nil
        self.token = nil
        self.connected = false
    }

    func send(_ message: API.SocketMessage, completionHandler: @escaping (Error?) -> Void) {
        guard let socket = self.socket,
              let encoded = try? JSONEncoder().encode(message) else { return }
        socket.send(.data(encoded), completionHandler: completionHandler)
    }

    func receive(completionHandler: @escaping (Result<API.SocketMessage, BasilError>) -> Void) {
        guard let socket = self.socket else { return }
        socket.receive { (result) in
            switch result {
            case .success(let response):
                switch response {
                case .data(let data):
                    if let message = try? JSONDecoder().decode(API.SocketMessage.self, from: data) {
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
        guard let userId = self.userId, let token = self.token else { return }
        // Send the user information and token to the server for validation
        let message = API.SocketMessage.authenticationRequest(userId: userId, token: token)
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
        self.userId = nil
        self.token = nil
        self.connected = false

        // If this was a server-initiated disconnect, notify the delegates
        if !self.clientDisconnect {
            var message = "Connection closed unexpectedly"
            if let reason, let reasonString = String(data: reason, encoding: .utf8) {
                message = reasonString
            }
            for delegate in self.delegates {
                delegate.socketError(.socketClosed(message))
            }
        }
    }
}
