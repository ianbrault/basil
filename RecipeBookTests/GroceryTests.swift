//
//  GroceryTests.swift
//  RecipeBookTests
//
//  Created by Ian Brault on 3/22/24.
//

import XCTest

final class GroceryTests: XCTestCase {

    func testGroceryNoQuantity() throws {
        var output: Grocery

        output = GroceryParser.shared.parse(string: "Eggs")
        XCTAssertEqual(output.quantity, .none)
        XCTAssertEqual(output.unit, nil)
        XCTAssertEqual(output.item, "Eggs")

        output = GroceryParser.shared.parse(string: " All-purpose  flour")
        XCTAssertEqual(output.quantity, .none)
        XCTAssertEqual(output.unit, nil)
        XCTAssertEqual(output.item, "All-purpose flour")

        output = GroceryParser.shared.parse(string: "Paper towels ")
        XCTAssertEqual(output.quantity, .none)
        XCTAssertEqual(output.unit, nil)
        XCTAssertEqual(output.item, "Paper towels")
    }

    func testGroceryBasicQuantity() throws {
        var output: Grocery

        output = GroceryParser.shared.parse(string: "2 apples")
        XCTAssertEqual(output.quantity, .integer(2))
        XCTAssertEqual(output.unit, nil)
        XCTAssertEqual(output.item, "apples")

        output = GroceryParser.shared.parse(string: "12  brown-butter chocolate chip cookies")
        XCTAssertEqual(output.quantity, .integer(12))
        XCTAssertEqual(output.unit, nil)
        XCTAssertEqual(output.item, "brown-butter chocolate chip cookies")
    }

    func testGroceryDecimalQuantity() throws {
        var output: Grocery

        output = GroceryParser.shared.parse(string: "1.5 lb. Alaskan salmon")
        XCTAssertEqual(output.quantity, .float(1.5))
        XCTAssertEqual(output.unit, .pounds)
        XCTAssertEqual(output.item, "Alaskan salmon")

        output = GroceryParser.shared.parse(string: "0.123 ounces chocolate chips")
        XCTAssertEqual(output.quantity, .float(0.123))
        XCTAssertEqual(output.unit, .ounces)
        XCTAssertEqual(output.item, "chocolate chips")
    }

    func testGroceryFractionQuantity() throws {
        var output: Grocery

        output = GroceryParser.shared.parse(string: "1/2 lb chicken breast")
        XCTAssertEqual(output.quantity, .fraction(Quantity.Fraction(1, 2)))
        XCTAssertEqual(output.unit, .pounds)
        XCTAssertEqual(output.item, "chicken breast")

        output = GroceryParser.shared.parse(string: "1 3/4 cups flour")
        XCTAssertEqual(output.quantity, .fraction(Quantity.Fraction(7, 4)))
        XCTAssertEqual(output.unit, .cups)
        XCTAssertEqual(output.item, "flour")

        output = GroceryParser.shared.parse(string: "10 5/8 tsp cinnamon")
        XCTAssertEqual(output.quantity, .fraction(Quantity.Fraction(85, 8)))
        XCTAssertEqual(output.unit, .teaspoons)
        XCTAssertEqual(output.item, "cinnamon")
    }

    func testGroceryUnicodeFractionQuantity() throws {
        var output: Grocery

        output = GroceryParser.shared.parse(string: "⅔ onion")
        XCTAssertEqual(output.quantity, .fraction(Quantity.Fraction(2, 3)))
        XCTAssertEqual(output.unit, nil)
        XCTAssertEqual(output.item, "onion")

        output = GroceryParser.shared.parse(string: "1¼ cups whole   milk")
        XCTAssertEqual(output.quantity, .fraction(Quantity.Fraction(5, 4)))
        XCTAssertEqual(output.unit, .cups)
        XCTAssertEqual(output.item, "whole milk")


        output = GroceryParser.shared.parse(string: "3 ⅞ beef rips")
        XCTAssertEqual(output.quantity, .fraction(Quantity.Fraction(31, 8)))
        XCTAssertEqual(output.unit, nil)
        XCTAssertEqual(output.item, "beef rips")
    }

    func testGroceryAddFractionsToWhole() throws {
        let a = Grocery(quantity: .fraction(Quantity.Fraction(3, 4)), unit: .pounds, item: "meat")
        let b = Grocery(quantity: .fraction(Quantity.Fraction(1, 4)), unit: .pounds, item: "meat")
        a.add(quantity: b.quantity)
        XCTAssertEqual(a.quantity, .integer(1))
        XCTAssertEqual(a.unit, .pounds)
        XCTAssertEqual(a.item, "meat")

        let c = Grocery(quantity: .fraction(Quantity.Fraction(7, 3)), unit: .cups, item: "whole milk")
        let d = Grocery(quantity: .fraction(Quantity.Fraction(2, 3)), unit: .cups, item: "whole milk")
        c.add(quantity: d.quantity)
        XCTAssertEqual(c.quantity, .integer(3))
        XCTAssertEqual(c.unit, .cups)
        XCTAssertEqual(c.item, "whole milk")
    }
}
