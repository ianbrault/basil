//
//  Unit.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/5/24.
//

import Foundation

enum Unit: Codable & Equatable {

    // weights
    case ounces
    case pounds
    case grams

    // volumes
    case teaspoons
    case tablespoons
    case cups

    private static let aliases: [Unit: Set<String>] = [
        .ounces: ["ounce", "ounces", "oz", "ozs"],
        .pounds: ["pound", "pounds", "lb", "lbs"],
        .grams: ["gram", "grams", "g"],
        .teaspoons: ["teaspoon", "teaspoons", "tsp", "tsps"],
        .tablespoons: ["tablespoon", "tablespoons", "tbsp", "tbsps"],
        .cups: ["cup", "cups", "c"],
    ]

    func toString() -> String {
        // currently using abbreviations, allow for more complex handling in the future
        switch self {
        case .ounces:
            return "oz."
        case .pounds:
            return "lb."
        case .grams:
            return "g"
        case .teaspoons:
            return "tsp"
        case .tablespoons:
            return "tbsp"
        case .cups:
            return "cup"
        }
    }

    static func from(string: String) -> Unit? {
        var string = string.trim()
        // remove decimals to simplify parse
        string = string.replacingOccurrences(of: ".", with: "")

        for (unit, unitAliases) in self.aliases {
            if unitAliases.contains(string) {
                return unit
            }
        }

        return nil
    }
}
