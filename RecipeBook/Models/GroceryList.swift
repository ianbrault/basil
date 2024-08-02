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

    private var incomplete: [Grocery] = []
    private var complete: [Grocery] = []

    var count: Int {
        return self.incomplete.count + self.complete.count
    }

    var isEmpty: Bool {
        return self.incomplete.isEmpty && self.complete.isEmpty
    }

    var items: [Grocery] {
        return self.incomplete + self.complete
    }

    func grocery(at indexPath: IndexPath) -> Grocery {
        if indexPath.row < self.incomplete.count {
            return self.incomplete[indexPath.row]
        } else {
            return self.complete[indexPath.row - self.incomplete.count]
        }
    }

    func addGrocery(_ grocery: Grocery){
        let _ = self.incomplete.add(grocery)
    }

    func addIngredients(from recipe: Recipe) {
        for ingredient in recipe.ingredients {
            let grocery = GroceryParser.shared.parse(string: ingredient)
            self.addGrocery(grocery)
        }
    }

    func remove(at indexPath: IndexPath) {
        if indexPath.row < self.incomplete.count {
            self.incomplete.remove(at: indexPath.row)
        } else {
            self.complete.remove(at: indexPath.row - self.incomplete.count)
        }
    }

    func replace(at indexPath: IndexPath, with grocery: Grocery) -> IndexPath {
        if indexPath.row < self.incomplete.count {
            // first check if the new grocery can be merged with any others in its list
            if let row = self.incomplete.tryMerge(grocery, excluding: indexPath.row) {
                self.remove(at: indexPath)
                return IndexPath(row: row, section: 0)
            } else {
                self.incomplete[indexPath.row] = grocery
                return indexPath
            }
        } else {
            // first check if the new grocery can be merged with any others in its list
            if let row = self.complete.tryMerge(grocery, excluding: indexPath.row - self.incomplete.count) {
                self.remove(at: indexPath)
                return IndexPath(row: row + self.incomplete.count, section: 0)
            } else {
                self.complete[indexPath.row - self.incomplete.count] = grocery
                return indexPath
            }
        }
    }

    func toggleComplete(at indexPath: IndexPath) -> IndexPath {
        let grocery = self.grocery(at: indexPath)
        grocery.toggleComplete()

        var row: Int
        if grocery.complete {
            // move from the incomplete list to head of the complete list
            self.remove(at: indexPath)
            row = self.complete.add(grocery, at: 0) + self.incomplete.count
        } else {
            // move from the complete list to the tail of the incomplete list
            self.remove(at: indexPath)
            row = self.incomplete.add(grocery)
        }
        return IndexPath(row: row, section: 0)
    }

    func clear() {
        self.incomplete.removeAll()
        self.complete.removeAll()
    }
}

extension Array<Grocery> {

    mutating func tryMerge(_ grocery: Grocery, excluding: Int? = nil) -> Int? {
        var index: Int? = nil
        let matches = self.enumerated().filter { $0.element.item == grocery.item }
        for (i, other) in matches {
            if let unit = grocery.unit, unit.canCombineWith(other.unit) {
                if let (newQuantity, newUnit) = Unit.combine(grocery.quantity, grocery.unit, other.quantity, other.unit) {
                    let newGrocery = Grocery(quantity: newQuantity, unit: newUnit, item: grocery.item)
                    self[i] = newGrocery
                    index = i
                    break
                }
            } else if other.unit == nil {
                self[i].add(quantity: grocery.quantity)
                index = i
                break
            }
        }
        return index
    }

    mutating func add(_ grocery: Grocery, at index: Int? = nil) -> Int {
        // first attempt to merge with an existing grocery in the target list
        if let i = self.tryMerge(grocery) {
            return i
        }
        // otherwise insert at the specified index, if provided
        if let index {
            self.insert(grocery, at: index)
            return index
        } else {
            // otherwise grocery does not exist in target list, append to end of list
            self.append(grocery)
            return self.count - 1
        }
    }
}
