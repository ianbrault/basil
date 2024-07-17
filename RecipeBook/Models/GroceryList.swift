//
//  GroceryList.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/17/24.
//

import Foundation

//
// Data structure representing the grocery list
// Handles merging logic to combine groceries when adding from multiple recipes
//
class GroceryList: Codable {

    class GroceryArray: Codable {

        private var list: [Grocery]
        private var set: Set<String>

        var count: Int {
            return self.list.count
        }

        var isEmpty: Bool {
            return self.list.isEmpty
        }

        var items: [Grocery] {
            return self.list
        }

        subscript(index: Int) -> Grocery {
            return self.list[index]
        }

        init() {
            self.list = []
            self.set = []
        }

        func clear() {
            self.list.removeAll()
            self.set.removeAll()
        }

        func contains(_ grocery: Grocery) -> Bool {
            return self.set.contains(grocery.item)
        }

        private func merge(_ grocery: Grocery) {
            let index =  self.list.firstIndex { $0.item == grocery.item }!
            self.list[index].add(quantity: grocery.quantity)
        }

        func add(_ grocery: Grocery) {
            if self.contains(grocery) {
                self.merge(grocery)
            } else {
                self.list.append(grocery)
                self.set.insert(grocery.item)
            }
        }

        func insert(_ grocery: Grocery, at index: Int) {
            if self.contains(grocery) {
                self.merge(grocery)
            } else {
                self.list.insert(grocery, at: index)
                self.set.insert(grocery.item)
            }
        }

        func remove(at index: Int) {
            let grocery = self.list.remove(at: index)
            self.set.remove(grocery.item)
        }

        func indexOf(_ grocery: Grocery) -> IndexPath? {
            if self.contains(grocery) {
                let index =  self.list.firstIndex { $0.item == grocery.item }!
                return IndexPath(row: index, section: 0)
            } else {
                return nil
            }
        }
    }

    var incomplete: GroceryArray
    var complete: GroceryArray

    var count: Int {
        return self.incomplete.count + self.complete.count
    }

    var isEmpty: Bool {
        return self.incomplete.isEmpty && self.complete.isEmpty
    }

    var items: [Grocery] {
        return self.incomplete.items + self.complete.items
    }

    init() {
        self.incomplete = GroceryArray()
        self.complete = GroceryArray()
    }

    func grocery(at indexPath: IndexPath) -> Grocery {
        if indexPath.row >= self.incomplete.count {
            return self.complete[indexPath.row - self.incomplete.count]
        } else {
            return self.incomplete[indexPath.row]
        }
    }

    func indexOf(grocery: Grocery) -> IndexPath? {
        if self.incomplete.contains(grocery) {
            return self.incomplete.indexOf(grocery)
        } else if self.complete.contains(grocery) {
            return self.complete.indexOf(grocery)
        } else {
            return nil
        }
    }

    func addIngredient(_ ingredient: String) {
        let grocery = GroceryParser.shared.parse(string: ingredient)
        self.incomplete.add(grocery)
    }

    func addIngredients(from recipe: Recipe) {
        for ingredient in recipe.ingredients {
            self.addIngredient(ingredient)
        }
    }

    func remove(at indexPath: IndexPath) {
        if indexPath.row >= self.incomplete.count {
            return self.complete.remove(at: indexPath.row - self.incomplete.count)
        } else {
            return self.incomplete.remove(at: indexPath.row)
        }
    }

    func clear() {
        self.incomplete.clear()
        self.complete.clear()
    }
}
