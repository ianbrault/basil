//
//  Parse.swift
//  RecipeBook
//
//  Created by Ian Brault on 9/3/23.
//

import Foundation
import SwiftSoup

class IngredientParser {

    static let shared = IngredientParser()

    var parts: [String] = []
    var index: Int = 0
    var quantity: Quantity = .none
    var unit: Unit? = nil

    private func quantityIsInt() -> Bool {
        switch self.quantity {
        case .integer(_):
            return true
        default:
            return false
        }
    }

    private func parseQuantity() {
        for part in self.parts[self.index...] {
            switch Quantity.from(string: part) {
            case .none:
                // stop parsing once no quantity can be parsed
                break
            case .integer(let integer):
                // do not parse back-to-back integers
                if self.quantityIsInt() {
                    break
                }
                self.quantity = self.quantity + .integer(integer)
                self.index += 1
            case .float(let float):
                self.quantity = self.quantity + .float(float)
                self.index += 1
                // stop parsing once a float is parsed
                break
            case .fraction(let fraction):
                self.quantity = self.quantity + .fraction(fraction)
                self.index += 1
                // stop parsing once a fraction is parsed
                break
            }
        }
    }

    private func parseUnit() {
        let part = self.parts[self.index]
        if let unit = Unit.from(string: part) {
            self.unit = unit
            self.index += 1
        }
    }

    func parse(string: String) -> Ingredient {
        // split by whitespace in order to parse individual components
        self.parts = string.trim()
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .map { $0.trim() }
        self.index = 0
        self.quantity = .none
        self.unit = nil

        self.parseQuantity()
        self.parseUnit()
        // remaining string is the item
        let item = self.parts[self.index...].joined(separator: " ")

        return Ingredient(quantity: self.quantity, unit: self.unit, item: item)
    }
}

enum NYTRecipeParser {

    static private func parseTitle(_ document: Document) throws -> String {
        let headers = try document.select("h1.pantry--title-display")
        if let header = headers.first() {
            return try header.text()
        } else {
            throw RBError.failedToParseRecipe("Failed to find recipe title")
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
                throw RBError.failedToParseRecipe("Failed to find instruction text")
            }
            let text = try paragraphs.map { try $0.text() }.joined(separator: " ")
            instructions.append(text)
        }

        return instructions
    }

    static func parse(body contents: Data, folderId: UUID) -> Result<Recipe, RBError> {
        guard let body = String(data: contents, encoding: .utf8) else {
            return .failure(.failedToDecode)
        }

        var document: Document
        do {
            document = try SwiftSoup.parse(body)
        } catch {
            return .failure(.failedToParseRecipe(error.localizedDescription))
        }

        do {
            // parse the recipe details
            let title = try self.parseTitle(document)
            let ingredients = try self.parseIngredients(document)
            let instructions = try self.parseInstructions(document)
            let recipe = Recipe(folderId: folderId, title: title, ingredients: ingredients, instructions: instructions)
            return .success(recipe)
        } catch {
            return .failure(.failedToParseRecipe(error.localizedDescription))
        }
    }
}
