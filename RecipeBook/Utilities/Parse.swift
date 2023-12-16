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

private func parseNYTRecipeIngredients(_ document: Document) throws -> [Ingredient] {
    let listItems = try document.select("li.pantry--ui")
    // down-select to list items with class ingredient_ingredient__*
    let ingredientItems = try listItems.filter { try isIngredientListItem($0) }

    var ingredients: [Ingredient] = []
    for item in ingredientItems {
        let ingredientText = try item.children().map { try $0.text() }.joined(separator: " ")
        ingredients.append(Ingredient(item: ingredientText))
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

private func parseNYTRecipeInstructions(_ document: Document) throws -> [Instruction] {
    let listItems = try document.getElementsByTag("li")
    // down-select to list items with class preparation_step__*
    let instructionItems = try listItems.filter { try isInstructionListItem($0) }

    var instructions: [Instruction] = []
    for item in instructionItems {
        let paragraphs = try item.getElementsByClass("pantry--body-long")
        if paragraphs.isEmpty() {
            throw RBError.failedToParseRecipe("Failed to find instruction text")
        }
        let instructionText = try paragraphs.map { try $0.text() }.joined(separator: " ")
        instructions.append(Instruction(step: instructionText))
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
        let recipe = Recipe(
            uuid: UUID(), folderId: folderId,
            title: title, ingredients: ingredients, instructions: instructions)
        return .success(recipe)
    } catch {
        return .failure(.failedToParseRecipe(error.localizedDescription))
    }
}
