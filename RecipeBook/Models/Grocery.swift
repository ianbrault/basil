//
//  Grocery.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/9/24.
//

import Foundation

class Grocery: Codable {

    var quantity: Quantity
    var unit: Unit?
    var item: String
    var complete: Bool

    init(quantity: Quantity, unit: Unit?, item: String) {
        self.quantity = quantity
        self.unit = unit
        self.item = item
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
        let new = self.quantity.add(quantity)
        self.quantity = new
    }
}
