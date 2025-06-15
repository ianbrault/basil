//
//  StyleGuide.swift
//  RecipeBook
//
//  Created by Ian Brault on 8/24/24.
//

import UIKit

struct StyleGuide {

    struct Color {
        let primary = UIColor.systemGreen

        let background = UIColor.systemBackground
        let secondaryBackground = UIColor.secondarySystemBackground
        let groupedBackground = UIColor.systemGroupedBackground

        let primaryText = UIColor.label
        let secondaryText = UIColor.secondaryLabel
        let tertiaryText = UIColor.tertiaryLabel

        let error = UIColor.systemRed
    }

    static let colors = Color()
    static let standardFontSize: CGFloat = 17
    static let tableCellHeight: CGFloat = 46
}
