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

    struct Font {
        let body = UIFont.preferredFont(forTextStyle: .body)
        let sectionHeader = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .subheadline).pointSize, weight: .semibold)
    }

    static let colors = Color()
    static let fonts = Font()

    static let tableCellHeight: CGFloat = 44
    static let tableCellHeightInteractive: CGFloat = 46
}
