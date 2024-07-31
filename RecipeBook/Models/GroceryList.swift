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

    private enum List {
        case incomplete
        case complete
    }

    var count: Int {
        return self.incomplete.count + self.complete.count
    }

    var isEmpty: Bool {
        return self.incomplete.isEmpty && self.complete.isEmpty
    }

    var items: [Grocery] {
        return self.incomplete + self.complete
    }

    private func indexOf(_ grocery: Grocery, in list: List) -> Int? {
        // NOTE: current implementation only allows merging for identical units
        // TODO: update this to allow conversions between equivalent unit types (i.e. volume, weight, etc.)
        switch list {
        case .incomplete:
            return self.incomplete.firstIndex { $0.item == grocery.item && $0.unit == grocery.unit }
        case .complete:
            return self.complete.firstIndex { $0.item == grocery.item && $0.unit == grocery.unit }
        }
    }

    private func add(_ grocery: Grocery, to list: List, at index: Int? = nil) -> IndexPath {
        var row: Int
        if let i = self.indexOf(grocery, in: list) {
            // grocery exists in target list, merging with existing grocery
            switch list {
            case .incomplete:
                self.incomplete[i].add(quantity: grocery.quantity)
                row = i
            case .complete:
                self.complete[i].add(quantity: grocery.quantity)
                row = self.complete.count + i
            }
        } else if let index {
            // grocery does not exist in target list, adding at specified index
            switch list {
            case .incomplete:
                self.incomplete.insert(grocery, at: index)
                row = index
            case .complete:
                self.complete.insert(grocery, at: index)
                row = self.incomplete.count + index
            }
        } else {
            // grocery does not exist in target list, append to end of list
            switch list {
            case .incomplete:
                row = self.incomplete.count
                self.incomplete.append(grocery)
            case .complete:
                row = self.incomplete.count + self.complete.count
                self.complete.append(grocery)
            }
        }
        return IndexPath(row: row, section: 0)
    }

    func grocery(at indexPath: IndexPath) -> Grocery {
        if indexPath.row < self.incomplete.count {
            return self.incomplete[indexPath.row]
        } else {
            return self.complete[indexPath.row - self.incomplete.count]
        }
    }

    func addGrocery(_ grocery: Grocery){
        let _ = self.add(grocery, to: .incomplete)
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

    func remove(at indexPath: IndexPath) {
        if indexPath.row >= self.incomplete.count {
            self.complete.remove(at: indexPath.row - self.incomplete.count)
        } else {
            self.incomplete.remove(at: indexPath.row)
        }
    }

    func replace(at indexPath: IndexPath, with grocery: Grocery) -> IndexPath {
        // check if the new grocery can be merged with any others in its list
        let list: List = indexPath.row < self.incomplete.count ? .incomplete : .complete
        if let index = self.indexOf(grocery, in: list), index != indexPath.row {
            self.remove(at: indexPath)
            return self.add(grocery, to: list)
        } else {
            switch list {
            case .incomplete:
                self.incomplete[indexPath.row] = grocery
            case .complete:
                self.complete[indexPath.row - self.incomplete.count] = grocery
            }
            return indexPath
        }
    }

    func toggleComplete(at indexPath: IndexPath) -> IndexPath {
        let grocery = self.grocery(at: indexPath)
        grocery.toggleComplete()

        var newIndexPath: IndexPath
        if grocery.complete {
            // move from the incomplete list to head of the complete list
            self.remove(at: indexPath)
            newIndexPath = self.add(grocery, to: .complete, at: 0)
        } else {
            // move from the complete list to the tail of the incomplete list
            self.remove(at: indexPath)
            newIndexPath = self.add(grocery, to: .incomplete)
        }
        return newIndexPath
    }

    func clear() {
        self.incomplete.removeAll()
        self.complete.removeAll()
    }
}
