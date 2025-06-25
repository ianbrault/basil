//
//  Ingredient.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/9/24.
//

import Foundation

class Ingredient: Decodable {

    var quantity: Quantity
    var unit: Unit?
    var item: String
    var complete: Bool

    var isEmpty: Bool {
        return self.quantity == .none && self.unit == nil && self.item.isEmpty
    }

    init(quantity: Quantity, unit: Unit?, item: String) {
        self.quantity = quantity
        self.unit = unit
        self.item = item
        self.complete = false
    }

    required init(from decoder: any Decoder) throws {
        let string = try decoder.singleValueContainer().decode(String.self)
        let ingredient = IngredientParser.shared.parse(string: string)
        self.quantity = ingredient.quantity
        self.unit = ingredient.unit
        self.item = ingredient.item
        self.complete = false
    }

    convenience init(item: String) {
        self.init(quantity: .none, unit: nil, item: item)
    }

    func toggleComplete() {
        self.complete = !self.complete
    }

    func toString() -> String {
        var s = ""
        if self.quantity != .none {
            s += self.quantity.toString() + " "
        }
        if let unit = self.unit {
            s += unit.toString() + " "
        }
        s += self.item
        return s
    }

    func add(quantity: Quantity) {
        self.quantity = self.quantity + quantity
    }

    static func empty() -> Ingredient {
        return Ingredient(item: "")
    }

    static func == (lhs: Ingredient, rhs: Ingredient) -> Bool {
        return (
            (lhs.item == rhs.item) &&
            (lhs.unit == rhs.unit) &&
            (lhs.quantity == rhs.quantity))
    }
}

extension Ingredient: Encodable {
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.toString())
    }
}

extension Ingredient: Hashable {
    var identifier: String {
        return self.toString()
    }

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(self.identifier)
    }
}
