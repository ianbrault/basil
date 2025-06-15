//
//  RecipeFormCell.swift
//  RecipeBook
//
//  Created by Ian Brault on 8/18/24.
//

import UIKit

class RecipeFormCell: UITableViewCell {
    static let textFieldReuseID = "RecipeFormCell__TF"
    static let buttonReuseID = "RecipeFormCell__BT"

    typealias Info = RecipeFormVC.Cell
    typealias Section = RecipeFormVC.Section

    var onChange: ((String) -> Void)?

    private func setTextField(with text: String?, for indexPath: IndexPath) {
        guard let text, let section = Section(rawValue: indexPath.section) else { return }
        var content = TextViewContentConfiguration()

        content.text = text
        content.placeholder = RecipeFormCell.textFieldPlaceholder(for: section)
        content.onChange =  { [weak self] (text) in
            self?.onChange?(text)
        }

        switch section {
        case .title:
            content.autocapitalizationType = .words
        case .ingredients, .instructions:
            content.autocapitalizationType = .sentences
        }

        self.contentConfiguration = content
        self.selectionStyle = .none
    }

    private func setButton(for indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else { return }
        var content = self.defaultContentConfiguration()

        content.image = SFSymbols.addRecipe
        content.imageProperties.tintColor = StyleGuide.colors.primary
        content.text = RecipeFormCell.buttonText(for: section)
        content.textProperties.color = StyleGuide.colors.primary

        self.contentConfiguration = content
        self.selectionStyle = .default
    }

    func set(_ info: Info, for indexPath: IndexPath) {
        switch info.style {
        case .textField:
            self.setTextField(with: info.text, for: indexPath)
        case .button:
            self.setButton(for: indexPath)
        }
    }

    static func buttonText(for section: Section) -> String {
        switch section {
        case .title:
            return ""
        case .ingredients:
            return "Add another ingredient"
        case .instructions:
            return "Add another step"
        }
    }

    static func textFieldPlaceholder(for section: Section) -> String {
        switch section {
        case .title:
            return "Title"
        case .ingredients:
            return "ex: 1 tbsp. olive oil"
        case .instructions:
            return "ex: Preheat the oven to 350°F"
        }
    }
}
