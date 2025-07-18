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

    private var groceries: [Ingredient] = []

    var count: Int {
        return self.groceries.count
    }

    var isEmpty: Bool {
        return self.groceries.isEmpty
    }

    var last: Ingredient? {
        return self.groceries.last
    }

    func grocery(at indexPath: IndexPath) -> Ingredient {
        return self.groceries[indexPath.row]
    }

    func indexOf(grocery: Ingredient) -> IndexPath? {
        return self.groceries.firstIndex { $0 == grocery }.map { IndexPath(row: $0, section: 0) }
    }

    func addIngredient(_ ingredient: Ingredient) {
        let _ = self.groceries.add(ingredient)
    }

    func addIngredients(from recipe: Recipe) {
        for ingredient in recipe.ingredients {
            if !ingredient.toString().starts(with: Recipe.sectionHeader) {
                self.addIngredient(ingredient)
            }
        }
    }

    func modify(at indexPath: IndexPath, with grocery: Ingredient) {
        self.groceries[indexPath.row] = grocery
    }

    func remove(at indexPath: IndexPath) {
        self.groceries.remove(at: indexPath.row)
    }

    func replace(at indexPath: IndexPath, with grocery: Ingredient) -> IndexPath {
        // first check if the new grocery can be merged with any others in its list
        if let row = self.groceries.tryMerge(grocery, excluding: indexPath.row) {
            self.remove(at: indexPath)
            return IndexPath(row: row, section: 0)
        } else {
            self.groceries[indexPath.row] = grocery
            return indexPath
        }
    }

    func toggleComplete(at indexPath: IndexPath) {
        self.grocery(at: indexPath).toggleComplete()
    }

    func sortCheckedGroceries() {
        let incomplete = self.groceries.filter { !$0.complete }
        let complete = self.groceries.filter { $0.complete }
        self.groceries = incomplete + complete
    }

    func mergeGroceries() {
        var new: [Ingredient] = []
        for grocery in self.groceries {
            let _ = new.add(grocery)
        }
        self.groceries = new
    }

    func clear() {
        self.groceries.removeAll()
    }
}

extension Array<Ingredient> {

    mutating func tryMerge(_ grocery: Ingredient, excluding: Int? = nil) -> Int? {
        var index: Int? = nil
        let matches = self.enumerated().filter { $0.element.item == grocery.item }
        for (i, other) in matches {
            if let unit = grocery.unit, unit.canCombineWith(other.unit) {
                if let (newQuantity, newUnit) = Unit.combine(grocery.quantity, grocery.unit, other.quantity, other.unit) {
                    let newGrocery = Ingredient(quantity: newQuantity, unit: newUnit, item: grocery.item)
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

    mutating func add(_ grocery: Ingredient, at index: Int? = nil) -> Int {
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
