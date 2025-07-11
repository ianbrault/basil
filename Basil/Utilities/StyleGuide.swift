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
        let button = UIFont.systemFont(ofSize: 18, weight: .semibold)
        let navigationBar = UIFont.systemFont(ofSize: 32, weight: .bold)
        let sectionHeader = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .subheadline).pointSize, weight: .semibold)
    }

    static let colors = Color()
    static let fonts = Font()

    static let buttonHeight: CGFloat = 54
    static let tableCellHeight: CGFloat = 44
    static let tableCellHeightInteractive: CGFloat = 46

    static var navigationBarAppearance: UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.largeTitleTextAttributes = [NSAttributedString.Key.font: Self.fonts.navigationBar]
        return appearance
    }
}
