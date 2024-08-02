//
//  Unit.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/5/24.
//

import Foundation

enum Unit: Codable & Equatable & Hashable {

    // weights
    case ounces
    case pounds
    case grams

    // volumes
    case teaspoons
    case tablespoons
    case cups

    static let ouncesPerPound = 16
    static let gramsPerOunce = 28.349523125
    static let teaspoonsPerTablespoon = 3
    static let tablespoonsPerCup = 16

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

    func canCombineWith(_ other: Unit?) -> Bool {
        guard let other else { return false }
        switch self {
        case .ounces, .pounds, .grams:
            switch other {
            case .ounces, .pounds, .grams:
                return true
            default:
                return false
            }
        case .teaspoons, .tablespoons, .cups:
            switch other {
            case .teaspoons, .tablespoons, .cups:
                return true
            default:
                return false
            }
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

    static func convert(_ quantity: Quantity, from: Unit, to: Unit) throws -> Quantity {
        switch from {
        case .ounces:
            switch to {
            case .ounces:
                return quantity
            case .pounds:
                return quantity.divideBy(integer: Unit.ouncesPerPound)
            case .grams:
                return quantity.multiplyBy(float: Unit.gramsPerOunce)
            default:
                throw RBError.invalidConversion(from, to)
            }
        case .pounds:
            switch to {
            case .ounces:
                return quantity.multiplyBy(integer: Unit.ouncesPerPound)
            case .pounds:
                return quantity
            case .grams:
                return quantity.multiplyBy(float: CGFloat(integerLiteral: Unit.ouncesPerPound) * Unit.gramsPerOunce)
            default:
                throw RBError.invalidConversion(from, to)
            }
        case .grams:
            switch to {
            case .ounces:
                return quantity.divideBy(float: Unit.gramsPerOunce)
            case .pounds:
                return quantity.divideBy(float: CGFloat(integerLiteral: Unit.ouncesPerPound) * Unit.gramsPerOunce)
            case .grams:
                return quantity
            default:
                throw RBError.invalidConversion(from, to)
            }
        case .teaspoons:
            switch to {
            case .teaspoons:
                return quantity
            case .tablespoons:
                return quantity.divideBy(integer: Unit.teaspoonsPerTablespoon)
            case .cups:
                return quantity.divideBy(integer: Unit.teaspoonsPerTablespoon * Unit.tablespoonsPerCup)
            default:
                throw RBError.invalidConversion(from, to)
            }
        case .tablespoons:
            switch to {
            case .teaspoons:
                return quantity.multiplyBy(integer: Unit.teaspoonsPerTablespoon)
            case .tablespoons:
                return quantity
            case .cups:
                return quantity.divideBy(integer: Unit.tablespoonsPerCup)
            default:
                throw RBError.invalidConversion(from, to)
            }
        case .cups:
            switch to {
            case .teaspoons:
                return quantity.multiplyBy(integer: Unit.tablespoonsPerCup * Unit.teaspoonsPerTablespoon)
            case .tablespoons:
                return quantity.multiplyBy(integer: Unit.tablespoonsPerCup)
            case .cups:
                return quantity
            default:
                throw RBError.invalidConversion(from, to)
            }
        }
    }

    static func simplify(_ quantity: Quantity, _ unit: Unit) -> (Quantity, Unit) {
        var finalQuantity = quantity
        var finalUnit = unit

        switch unit {
        case .ounces:
            let pounds = quantity.divideBy(integer: Unit.ouncesPerPound)
            if pounds.asFloat() >= 1.0 {
                finalQuantity = pounds
                finalUnit = .pounds
            }
        case .teaspoons:
            let tablespoons = quantity.divideBy(integer: Unit.teaspoonsPerTablespoon)
            if tablespoons.asFloat() >= 1.0 {
                // attempt to convert upwards again to cups
                (finalQuantity, finalUnit) = Unit.simplify(tablespoons, .tablespoons)
            }
        case .tablespoons:
            let cups = quantity.divideBy(integer: Unit.tablespoonsPerCup)
            if cups.asFloat() >= 1.0 {
                finalQuantity = cups
                finalUnit = .cups
            }
        case .pounds, .grams, .cups:
            // no further simplification for these units
            break
        }

        return (finalQuantity, finalUnit)
    }

    static func combine(
        _ quantityA: Quantity, _ unitA: Unit?,
        _ quantityB: Quantity, _ unitB: Unit?
    ) -> (Quantity, Unit)? {
        guard let unitA, let unitB, unitA.canCombineWith(unitB) else { return nil }

        if unitA == unitB {
            let quantity = quantityA.add(quantityB)
            return Unit.simplify(quantity, unitA)
        }

        switch unitA {
        // weight
        case .grams, .ounces, .pounds:
            // if both are metric, keep in metric; otherwise convert to imperial
            let unit = (unitA == .grams && unitB == .grams) ? Unit.grams : Unit.ounces
            let a = try! Unit.convert(quantityA, from: unitA, to: unit)
            let b = try! Unit.convert(quantityB, from: unitB, to: unit)
            let quantity = a.add(b)
            return Unit.simplify(quantity, unit)
        // volume
        case .teaspoons, .tablespoons, .cups:
            let unit = Unit.teaspoons
            let a = try! Unit.convert(quantityA, from: unitA, to: unit)
            let b = try! Unit.convert(quantityB, from: unitB, to: unit)
            let quantity = a.add(b)
            return Unit.simplify(quantity, unit)
        }
    }
}
