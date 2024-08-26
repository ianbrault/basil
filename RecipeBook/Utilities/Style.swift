//
//  Style.swift
//  RecipeBook
//
//  Created by Ian Brault on 8/24/24.
//

import UIKit

struct Style {

    struct Color {
        let primary = UIColor.systemYellow
        let secondary = UIColor.paleYellow

        let background = UIColor.systemBackground
        let secondaryBackground = UIColor.secondarySystemBackground
        let styledBackground = UIColor.paleYellow

        let primaryText = UIColor.label
        let secondaryText = UIColor.secondaryLabel
        let styledText = UIColor.darkYellow

        let error = UIColor.systemRed
    }

    static let colors = Color()
    static let tableCellHeight: CGFloat = 46
}
