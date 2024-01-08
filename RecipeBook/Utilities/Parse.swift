//
//  Parse.swift
//  RecipeBook
//
//  Created by Ian Brault on 9/3/23.
//

import Foundation
import SwiftSoup

struct UserLoginResponse: Decodable {
    let id: String
    let key: UUID
    let root: UUID?
    let recipes: [Recipe]
    let folders: [RecipeFolder]
}

private func parseNYTRecipeTitle(_ document: Document) throws -> String {
    let headers = try document.select("h1.pantry--title-display")
    if let header = headers.first() {
        return try header.text()
    } else {
        throw RBError.failedToParseRecipe("Failed to find recipe title")
    }
}

private func isIngredientListItem(_ element: Element) throws -> Bool {
    let classes = Array(try element.classNames())
    for classname in classes {
        if classname.contains("ingredient_ingredient") {
            return true
        }
    }
    return false
}

private func parseNYTRecipeIngredients(_ document: Document) throws -> [String] {
    let listItems = try document.select("li.pantry--ui")
    // down-select to list items with class ingredient_ingredient__*
    let ingredientItems = try listItems.filter { try isIngredientListItem($0) }

    var ingredients: [String] = []
    for item in ingredientItems {
        let text = try item.children().map { try $0.text() }.joined(separator: " ")
        ingredients.append(text)
    }

    return ingredients
}

private func isInstructionListItem(_ element: Element) throws -> Bool {
    let classes = Array(try element.classNames())
    for classname in classes {
        if classname.contains("preparation_step") {
            return true
        }
    }
    return false
}

private func parseNYTRecipeInstructions(_ document: Document) throws -> [String] {
    let listItems = try document.getElementsByTag("li")
    // down-select to list items with class preparation_step__*
    let instructionItems = try listItems.filter { try isInstructionListItem($0) }

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

func parseNYTRecipe(body contents: Data, folderId: UUID) -> Result<Recipe, RBError> {
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
        let title = try parseNYTRecipeTitle(document)
        let ingredients = try parseNYTRecipeIngredients(document)
        let instructions = try parseNYTRecipeInstructions(document)
        let recipe = Recipe(folderId: folderId, title: title, ingredients: ingredients, instructions: instructions)
        return .success(recipe)
    } catch {
        return .failure(.failedToParseRecipe(error.localizedDescription))
    }
}
