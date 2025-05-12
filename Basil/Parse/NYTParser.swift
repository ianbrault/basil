//
//  NYTParser.swift
//  Basil
//
//  Created by Ian Brault on 5/12/25.
//

import Foundation
import SwiftSoup

struct NYTRecipeParser {

    private init() {}

    static private func parseTitle(_ document: Document) throws -> String {
        let headers = try document.select("h1.pantry--title-display")
        if let header = headers.first() {
            return try header.text()
        } else {
            throw BasilError.recipeParseError("Failed to find recipe title")
        }
    }

    static private func isIngredientListItem(_ element: Element) throws -> Bool {
        let classes = Array(try element.classNames())
        for classname in classes {
            if classname.contains("ingredient_ingredient") {
                return true
            }
        }
        return false
    }

    static private func parseIngredients(_ document: Document) throws -> [Ingredient] {
        let listItems = try document.select("li.pantry--ui")
        // down-select to list items with class ingredient_ingredient__*
        let ingredientItems = try listItems.filter { try self.isIngredientListItem($0) }

        var ingredients: [Ingredient] = []
        for item in ingredientItems {
            let text = try item.children().map { try $0.text() }.joined(separator: " ")
            let ingredient = IngredientParser.shared.parse(string: text)
            ingredients.append(ingredient)
        }

        return ingredients
    }

    static private func isInstructionListItem(_ element: Element) throws -> Bool {
        let classes = Array(try element.classNames())
        for classname in classes {
            if classname.contains("preparation_step") {
                return true
            }
        }
        return false
    }

    static private func parseInstructions(_ document: Document) throws -> [String] {
        let listItems = try document.getElementsByTag("li")
        // down-select to list items with class preparation_step__*
        let instructionItems = try listItems.filter { try self.isInstructionListItem($0) }

        var instructions: [String] = []
        for item in instructionItems {
            let paragraphs = try item.getElementsByClass("pantry--body-long")
            if paragraphs.isEmpty() {
                throw BasilError.recipeParseError("Failed to find instruction text")
            }
            let text = try paragraphs.map { try $0.text() }.joined(separator: " ")
            instructions.append(text)
        }

        return instructions
    }

    static func parse(body contents: Data, folderId: UUID) -> Result<Recipe, BasilError> {
        guard let body = String(data: contents, encoding: .utf8) else {
            return .failure(.decodeError)
        }

        var document: Document
        do {
            document = try SwiftSoup.parse(body)
        } catch {
            return .failure(.recipeParseError(error.localizedDescription))
        }

        do {
            // parse the recipe details
            let title = try self.parseTitle(document)
            let ingredients = try self.parseIngredients(document)
            let instructions = try self.parseInstructions(document)
            let recipe = Recipe(folderId: folderId, title: title, ingredients: ingredients, instructions: instructions)
            return .success(recipe)
        } catch {
            return .failure(.recipeParseError(error.localizedDescription))
        }
    }
}
