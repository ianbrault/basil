//
//  Grocery.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/9/24.
//

import Foundation

class Grocery: Codable {

    var quantity: CGFloat
    var unit: String  // TODO: enum
    var item: String
    var complete: Bool

    init(item: String) {
        self.quantity = 0
        self.unit = ""
        self.item = item
        self.complete = false
    }

    func toggleComplete() {
        self.complete = !self.complete
    }
}
