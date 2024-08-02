//
//  UnitTests.swift
//  RecipeBookTests
//
//  Created by Ian Brault on 8/1/24.
//

import XCTest

final class UnitTests: XCTestCase {

    func testUnitCombineBasic() throws {
        var result: (Quantity, Unit)?

        result = Unit.combine(.integer(1), .grams, .float(0.5), .grams)
        XCTAssertNotNil(result)
        if let (quantity, unit) = result {
            XCTAssertEqual(quantity, .float(1.5))
            XCTAssertEqual(unit, .grams)
        }

        result = Unit.combine(.integer(1), .cups, .fraction(Quantity.Fraction(3, 4)), .cups)
        XCTAssertNotNil(result)
        if let (quantity, unit) = result {
            XCTAssertEqual(quantity, .fraction(Quantity.Fraction(7, 4)))
            XCTAssertEqual(unit, .cups)
        }
    }

    func testUnitCombineConvert() throws {
        var result: (Quantity, Unit)?

        result = Unit.combine(.integer(150), .grams, .integer(1), .ounces)
        XCTAssertNotNil(result)
        if let (quantity, unit) = result {
            XCTAssertEqual(quantity, .float((150 / Unit.gramsPerOunce) + 1))
            XCTAssertEqual(unit, .ounces)
        }
    }

    func testUnitCombineAndSimplify() throws {
        var result: (Quantity, Unit)?

        result = Unit.combine(.integer(9), .ounces, .integer(9), .ounces)
        XCTAssertNotNil(result)
        if let (quantity, unit) = result {
            XCTAssertEqual(quantity, .float(1.125))
            XCTAssertEqual(unit, .pounds)
        }

        result = Unit.combine(.integer(2), .teaspoons, .fraction(Quantity.Fraction(3, 2)), .tablespoons)
        XCTAssertNotNil(result)
        if let (quantity, unit) = result {
            XCTAssertEqual(quantity, .fraction(Quantity.Fraction(13, 6)))
            XCTAssertEqual(unit, .tablespoons)
        }

        result = Unit.combine(.integer(16), .teaspoons, .integer(32), .teaspoons)
        XCTAssertNotNil(result)
        if let (quantity, unit) = result {
            XCTAssertEqual(quantity, .integer(1))
            XCTAssertEqual(unit, .cups)
        }

    }
}
