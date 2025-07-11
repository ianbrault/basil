//
//  NoteParser.swift
//  Basil
//
//  Created by Ian Brault on 6/29/25.
//

import Foundation

class NoteParser {

    static let shared = NoteParser()

    private static let ingredientsHeadings = ["ingredients"]
    private static let instructionsHeadings = ["instructions", "directions"]

    private static let listStart = /^(?:-|\*|\+|⁃|•|\d+\.)\s*(.+)/

    private init() {}

    private func startsIngredients(_ text: String) -> Bool {
        // ensure the text is lowercased before passing it in
        return Self.ingredientsHeadings.firstIndex { text.starts(with: $0) } != nil
    }

    private func startsInstructions(_ text: String) -> Bool {
        // ensure the text is lowercased before passing it in
        return Self.instructionsHeadings.firstIndex { text.starts(with: $0) } != nil
    }

    func parse(text: String, inFolder folderId: UUID? = nil) -> Result<Recipe, BasilError> {
        let lines = text.split(separator: "\n").map { String($0).trim() }.filter { !$0.isEmpty }
        if lines.isEmpty {
            return .failure(.recipeParseError("Empty input"))
        }

        let parentFolder = State.manager.root ?? folderId ?? UUID()
        let recipe = Recipe(folderId: parentFolder, title: lines[0])

        var inIngredients = false
        var inInstructions = false
        for line in lines[1...] {
            let lline = line.lowercased()
            // check for start of ingredients/instructions sections
            if !inIngredients && !inInstructions && startsIngredients(lline) {
                inIngredients = true
                continue
            } else if inIngredients && startsInstructions(lline) {
                inIngredients = false
                inInstructions = true
                continue
            }
            if !inIngredients && !inInstructions {
                continue
            }
            // otherwise parse the current ingredient/instruction
            // first check if the line starts with a list header
            var text: String
            if let match = line.firstMatch(of: Self.listStart) {
                text = String(match.output.1)
            } else {
                // otherwise assume that this is a section
                text = "__SECTION__ \(line)"
            }
            if text.trim().isEmpty {
                continue
            }
            if inIngredients {
                let ingredient = IngredientParser.shared.parse(string: text)
                recipe.ingredients.append(ingredient)
            } else if inInstructions {
                recipe.instructions.append(text)
            }
        }

        return .success(recipe)
    }
}
