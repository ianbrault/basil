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
        func didPushToServer()
        func didReceiveSyncRequest(_: API.SyncRequestBody)
        func socketError(_: BasilError)
    }

    enum SocketState {
        case Disconnected
        case NeedsAuthentication
        case Connected
        case UpdateRequested
    }

    // let socketURL = URL(string: "ws://localhost:4040")!
    // let socketURL = URL(string: "wss://brault.dev/nightly/basil/socket")!
    let socketURL = URL(string: "wss://brault.dev/basil/socket")!

    private var delegates: [Delegate] = []
    private var socket: URLSessionWebSocketTask? = nil
    private var userId: String? = nil
    private var token: String? = nil
    private var state: SocketState = .Disconnected
    private var clientDisconnect: Bool = false

    static let shared = SocketManager()
    static let pingInterval = 10.0

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
        self.setPingHandler()
        self.setReceiveHandler()
    }

    private func closeSocket(with closeCode: URLSessionWebSocketTask.CloseCode, reason: String? = nil) {
        let reasonData = reason?.data(using: .utf8)
        self.socket?.cancel(with: closeCode, reason: reasonData)
        self.socket = nil
        self.userId = nil
        self.token = nil
        self.state = .Disconnected
    }

    func disconnect() {
        // signal to any methods handling disconnects that we initiated this
        self.clientDisconnect = true
        self.closeSocket(with: .goingAway)
    }

    func sendUpdate() {
        self.state = .UpdateRequested
        // Send the user information and token to the server for validation
        let message = API.SocketMessage.updateRequest(
            root: State.manager.root,
            recipes: State.manager.recipes,
            folders: State.manager.folders,
        )
        self.send(message) { [weak self] (error) in
            if let error {
                self?.socketError(.socketWriteError(error.localizedDescription))
            }
        }
    }

    private func send(_ message: API.SocketMessage, completionHandler: @escaping (Error?) -> Void) {
        guard let socket = self.socket,
              let encoded = try? JSONEncoder().encode(message) else { return }
        socket.send(.data(encoded), completionHandler: completionHandler)
    }

    private func socketError(_ error: BasilError) {
        for delegate in self.delegates {
            delegate.socketError(error)
        }
    }

    private func setPingHandler() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.pingInterval) {
            self.socket?.sendPing { [weak self] (error) in
                if let _ = error {
                    // only report the error if this is a non-user-initiated disconnect
                    if !(self?.clientDisconnect ?? false) {
                        self?.closeSocket(with: .abnormalClosure)
                        self?.socketError(.socketClosed("Connection closed unexpectedly"))
                    }
                } else {
                    self?.setPingHandler()
                }
            }
        }
    }

    private func setReceiveHandler() {
        self.socket?.receive { [weak self] (result) in
            defer {
                if let self, self.state != .Disconnected {
                    self.setReceiveHandler()
                }
            }
            switch result {
            case .success(let response):
                switch response {
                case let .data(data):
                    if let message = try? JSONDecoder().decode(API.SocketMessage.self, from: data) {
                        self?.messageReceived(message)
                    } else {
                        self?.socketError(.socketReadError("Failed to decode message"))
                    }
                case let .string(string):
                    self?.socketError(.socketReadError("Unexpected string data: \(string)"))
                @unknown default:
                    self?.socketError(.socketReadError("Unexected data of unknown type"))
                }
            case .failure(let error):
                // POSIX error 57 indicates that the socket is no longer connected
                let nsError = error as NSError
                if nsError.domain == NSPOSIXErrorDomain && nsError.code == 57 {
                    // only report the error if this is a non-user-initiated disconnect
                    if !(self?.clientDisconnect ?? false) {
                        self?.closeSocket(with: .abnormalClosure)
                        self?.socketError(.socketClosed("Connection closed unexpectedly"))
                    }
                } else {
                    self?.socketError(.socketReadError(error.localizedDescription))
                }
            }
        }
    }

    private func messageReceived(_ message: API.SocketMessage) {
        switch message {
        case .Success:
            switch self.state {
            case .NeedsAuthentication:
                // User authentication successful
                self.state = .Connected
                for delegate in self.delegates {
                    delegate.didConnectToServer()
                }
            case .UpdateRequested:
                // User updates pushed to the server successfully
                self.state = .Connected
                for delegate in self.delegates {
                    delegate.didPushToServer()
                }
            default:
                self.socketError(.socketUnexpectedMessage(message.messageType, self.state))
            }
        case .SyncRequest(let body):
            switch self.state {
            case .Connected, .UpdateRequested:
                // Someone made changes on another device
                for delegate in self.delegates {
                    delegate.didReceiveSyncRequest(body)
                }
            default:
                self.socketError(.socketUnexpectedMessage(message.messageType, self.state))
            }
        case .AuthenticationError(let errorMessage):
            switch self.state {
            case .NeedsAuthentication:
                // An error occurred during user authentication
                self.socketError(.socketReadError(errorMessage))
            default:
                self.socketError(.socketUnexpectedMessage(message.messageType, self.state))
            }
        case .UpdateError(let errorMessage):
            switch self.state {
            case .UpdateRequested:
                // An error occurred pushing user updates to the server
                self.socketError(.socketReadError(errorMessage))
            default:
                self.socketError(.socketUnexpectedMessage(message.messageType, self.state))
            }
        default:
            self.socketError(.socketUnexpectedMessage(message.messageType, self.state))
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
        self.state = .NeedsAuthentication
        // Send the user information and token to the server for validation
        let message = API.SocketMessage.authenticationRequest(userId: userId, token: token)
        self.send(message) { [weak self] (error) in
            if let error {
                self?.socketError(.socketWriteError(error.localizedDescription))
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
        self.closeSocket(with: .goingAway)

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
