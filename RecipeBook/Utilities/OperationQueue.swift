//
//  OperationQueue.swift
//  RecipeBook
//
//  Created by Ian Brault on 2/24/24.
//

import Foundation

class OperationQueue: Codable {

    enum OperationType: Codable {
        case create
        case delete
        case update
    }

    struct Item: Codable {
        let type: OperationType
        let recipes: [Recipe]
        let folders: [RecipeFolder]
        let recipeUUIDs: [UUID]
        let folderUUIDs: [UUID]
    }

    var items: [Item] = []

    func addOperation(
        _ type: OperationType,
        recipes: [Recipe] = [], folders: [RecipeFolder] = [], recipeUUIDs: [UUID] = [], folderUUIDs: [UUID] = []
    ) {
        let item = Item(type: type, recipes: recipes, folders: folders, recipeUUIDs: recipeUUIDs, folderUUIDs: folderUUIDs)
        self.items.append(item)
    }

    private func processOperation(_ operation: Item, completion: @escaping (RBError?) -> ()) {
        switch operation.type {
        case .create:
            let recipe = operation.recipes.isEmpty ? nil : operation.recipes[0]
            let folder = operation.folders.isEmpty ? nil : operation.folders[0]
            API.createItem(recipe: recipe, folder: folder, handler: completion)
        case .delete:
            API.deleteItems(recipes: operation.recipeUUIDs, folders: operation.folderUUIDs, handler: completion)
        case .update:
            API.updateItems(recipes: operation.recipes, folders: operation.folders, handler: completion)
        }
    }

    func processOperations(handler: @escaping (RBError?) -> ()) {
        if self.items.isEmpty {
            handler(nil)
            return
        }

        // process the next item on the queue
        self.processOperation(self.items.first!) { (error) in
            if let error {
                // if the operation returned an error, send to the handler and stop processing
                handler(error)
            } else {
                // otherwise, pop the operation off of the queue and continue processing on the next operation
                self.items.removeFirst()
                self.processOperations(handler: handler)
            }
        }
    }
}
