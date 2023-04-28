//
//  PersistenceManager.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/6/23.
//

import Foundation

enum PersistenceManager {
    static private let defaults = UserDefaults.standard

    enum Keys {
        static let recipes = "recipes"
    }

    // TODO: debug function, delete later
    static func deleteRecipes(completed: @escaping (RBError?) -> Void) {
        do {
            let encoder = JSONEncoder()
            let recipes: [Recipe] = []
            let encodedRecipes = try encoder.encode(recipes)
            defaults.set(encodedRecipes, forKey: Keys.recipes)
            completed(nil)
        } catch {
            completed(.failedToSaveRecipes)
        }
    }

    static func fetchRecipes(completed: @escaping (Result<[Recipe], RBError>) -> Void) {
        guard let recipesData = defaults.object(forKey: Keys.recipes) as? Data else {
            // if this is nil, nothing has been saved before
            completed(.success([]))
            return
        }

        do {
            let decoder = JSONDecoder()
            let recipes = try decoder.decode([Recipe].self, from: recipesData)
            completed(.success(recipes))
        } catch {
            completed(.failure(.failedToLoadRecipes))
        }
    }

    static func saveRecipes(recipes: [Recipe], completed: @escaping (RBError?) -> Void) {
        do {
            let encoder = JSONEncoder()
            let encodedRecipes = try encoder.encode(recipes)
            defaults.set(encodedRecipes, forKey: Keys.recipes)
            completed(nil)
        } catch {
            completed(.failedToSaveRecipes)
        }
    }

    static func saveRecipe(recipe: Recipe, completed: @escaping (RBError?) -> Void) {
        fetchRecipes { (result) in
            switch result {
            case .success(var recipes):
                if let i = recipes.firstIndex(where: { $0.uuid == recipe.uuid }) {
                    recipes[i] = recipe
                    saveRecipes(recipes: recipes) { (error) in
                        completed(error)
                    }
                } else {
                    completed(.missingRecipe(recipe.uuid))
                }

            case .failure(let error):
                completed(error)
            }
        }
    }
}
