//
//  IngredientParser.swift
//  Basil
//
//  Created by Ian Brault on 5/12/25.
//

import Foundation

class IngredientParser {

    var parts: [String] = []
    var index: Int = 0
    var quantity: Quantity = .none
    var unit: Unit? = nil

    static let shared = IngredientParser()

    private init() {}

    private func quantityIsInt() -> Bool {
        switch self.quantity {
        case .integer(_):
            return true
        default:
            return false
        }
    }

    private func parseQuantity() {
        for part in self.parts[self.index...] {
            switch Quantity.from(string: part) {
            case .none:
                // stop parsing once no quantity can be parsed
                break
            case .integer(let integer):
                // do not parse back-to-back integers
                if self.quantityIsInt() {
                    break
                }
                self.quantity = self.quantity + .integer(integer)
                self.index += 1
            case .float(let float):
                self.quantity = self.quantity + .float(float)
                self.index += 1
                // stop parsing once a float is parsed
                break
            case .fraction(let fraction):
                self.quantity = self.quantity + .fraction(fraction)
                self.index += 1
                // stop parsing once a fraction is parsed
                break
            }
        }
    }

    private func parseUnit() {
        guard self.index < self.parts.count else {
            self.unit = nil
            return
        }
        let part = self.parts[self.index]
        if let unit = Unit.from(string: part) {
            self.unit = unit
            self.index += 1
        }
    }

    func parse(string: String) -> Ingredient {
        // split by whitespace in order to parse individual components
        self.parts = string.trim()
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .map { $0.trim() }
        self.index = 0
        self.quantity = .none
        self.unit = nil

        // if there is only 1 part, don't try to parse quantity/unit
        if self.parts.count == 1 {
            return Ingredient(quantity: .none, unit: nil, item: self.parts[0])
        }

        self.parseQuantity()
        self.parseUnit()
        // remaining string is the item
        let item = self.parts[self.index...].joined(separator: " ")

        return Ingredient(quantity: self.quantity, unit: self.unit, item: item)
    }
}
