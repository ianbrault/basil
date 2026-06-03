//
//  Result+Ext.swift
//  Basil
//
//  Created by Ian Brault on 3/6/26.
//

extension Result {
    var isSuccess: Bool {
        if case .success = self { return true } else { return false }
    }

    var isError: Bool { return !isSuccess }
}
