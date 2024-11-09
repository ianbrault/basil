//
//  Security.swift
//  RecipeBook
//
//  Created by Ian Brault on 12/3/23.
//

import CryptoKit
import Foundation

func hashPassword(_ password: String) -> Result<Data, RBError> {
    guard let passwordData = password.data(using: .utf8) else {
        return .failure(.failedToEncode)
    }

    let hash = SHA256.hash(data: passwordData)
    return .success(Data(hash))
}
