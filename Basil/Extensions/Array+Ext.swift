//
//  Array+Ext.swift
//  Basil
//
//  Created by Ian Brault on 7/11/25.
//

import Foundation

extension Array {

    func filterMap<T>(_ transform: (Element) -> T?) -> [T] {
        return self.map(transform).filter { $0 != nil }.map { $0! }
    }

    mutating func popFirst() -> Element? {
        if self.isEmpty {
            return nil
        } else {
            return self.removeFirst()
        }
    }
}

extension Array<RecipeItem> {

    func findItem(uuid: UUID) -> IndexPath? {
        var indexPath: IndexPath? = nil
        for (index, item) in self.enumerated() {
            if item.uuid == uuid {
                indexPath = IndexPath(row: index, section: 0)
                break
            }
        }
        return indexPath
    }
}
