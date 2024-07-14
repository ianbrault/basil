//
//  GroceryList.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/17/24.
//

import Foundation

class GroceryList: Codable {

    var groceries: [Grocery]
    var groceryItems: Set<String>

    var count: Int {
        return self.groceries.count
    }

    var isEmpty: Bool {
        return self.groceries.isEmpty
    }

    init() {
        self.groceries = []
        self.groceryItems = []
    }

    func grocery(at indexPath: IndexPath) -> Grocery {
        return self.groceries[indexPath.row]
    }

    func toggleComplete(at indexPath: IndexPath) {
        self.groceries[indexPath.row].toggleComplete()
    }

    private func addGrocery(_ grocery: Grocery) {
        if self.groceryItems.contains(grocery.item) {
            // TODO: add merging logic
        } else {
            self.groceries.append(grocery)
            self.groceryItems.insert(grocery.item)
        }
    }

    func addIngredient(_ ingredient: String) {
        let grocery = GroceryParser.shared.parse(string: ingredient)
        self.addGrocery(grocery)
    }

    func addIngredients(from recipe: Recipe) {
        for ingredient in recipe.ingredients {
            self.addIngredient(ingredient)
        }
    }
}
