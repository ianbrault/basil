//
//  String+Ext.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/22/24.
//

import Foundation

extension String {

    func index(from: Int) -> Index {
        return self.index(self.startIndex, offsetBy: from)
    }

    func substring(from: Int) -> String {
        let fromIndex = self.index(from: from)
        return String(self[fromIndex...])
    }

    func substring(to: Int) -> String {
        let toIndex = self.index(from: to)
        return String(self[..<toIndex])
    }

    func substring(with r: Range<Int>) -> String {
        let startIndex = self.index(from: r.lowerBound)
        let endIndex = self.index(from: r.upperBound)
        return String(self[startIndex..<endIndex])
    }

    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
