//
//  ObjectID.swift
//  Basil
//
//  Created by Ian Brault on 4/12/26.
//

import Foundation

final class ObjectID: Equatable {
    private static let device = Int.random(in: 0...0xFFFFFF)
    private static var counter = Int.random(in: 0...0xFFFFFF)

    private let id: String

    enum CodingKeys: String, CodingKey {
        case oid = "$oid"
    }

    init() {
        // Timestamp: 4 bytes
        let timestamp = String(
            format: "%08x",
            UInt32(Date().timeIntervalSince1970)
        )
        // Device ID: 3 bytes
        let device = String(format: "%06x", Self.device)
        // PID: 2 bytes
        let pid = String(
            format: "%04x",
            ProcessInfo.processInfo.processIdentifier & 0xFFFF
        )
        // Counter: 3 bytes
        let counter = String(format: "%06x", Self.counter)
        Self.counter = (Self.counter + 1) % 0x1000000

        self.id = timestamp + device + pid + counter
    }

    init(string: String) {
        self.id = string
    }

    static func == (lhs: ObjectID, rhs: ObjectID) -> Bool {
        return lhs.id == rhs.id
    }
}

extension ObjectID: CustomStringConvertible {
    var description: String {
        return self.id
    }
}

extension ObjectID: Hashable {
    var identifier: String {
        return self.id
    }

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(self.identifier)
    }
}

extension ObjectID: Decodable {
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .oid)
        self.init(string: id)
    }
}

extension ObjectID: Encodable {
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .oid)
    }
}
