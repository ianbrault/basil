//
//  QuantityTests.swift
//  RecipeBookTests
//
//  Created by Ian Brault on 8/6/24.
//

import XCTest

final class QuantityTests: XCTestCase {

    func testQuantityAddFractionsToWhole() throws {
        let a = Quantity.fraction(Quantity.Fraction(3, 4))
        let b = Quantity.fraction(Quantity.Fraction(1, 4))
        let c = a + b
        XCTAssertEqual(c, .integer(1))

        let d = Quantity.fraction(Quantity.Fraction(7, 3))
        let e = Quantity.fraction(Quantity.Fraction(2, 3))
        let f = d + e
        XCTAssertEqual(f, .integer(3))
    }
}
