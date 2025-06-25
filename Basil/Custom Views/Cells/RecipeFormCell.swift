//
//  RecipeFormCell.swift
//  RecipeBook
//
//  Created by Ian Brault on 8/18/24.
//

import UIKit

class RecipeFormCell: UITableViewCell {
    static let textFieldReuseID = "RecipeFormCell__TextField"
    static let buttonReuseID = "RecipeFormCell__Button"

    typealias Info = RecipeFormVC.Cell
    typealias Section = RecipeFormVC.Section

    enum TapLocation {
        case item
        case section
    }

    var onChange: ((String) -> Void)?
    var onBeginEditing: ((String) -> Void)?
    var onEndEditing: ((String) -> Void)?
    var onButtonTap: ((UITableViewCell, TapLocation) -> Void)?

    private var isSectionHeader: Bool = false

    override func becomeFirstResponder() -> Bool {
        self.contentView.becomeFirstResponder()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.isSectionHeader = false
    }

    private func setTextField(with text: String?, for indexPath: IndexPath) {
        guard let text, let section = Section(rawValue: indexPath.section) else { return }
        var content = TextViewContentConfiguration()

        content.tintColor = StyleGuide.colors.tertiaryText
        content.imageSize = 20
        content.imageToTextPadding = 6
        if section != .title && text.starts(with: Recipe.sectionHeader) {
            self.isSectionHeader = true
            content.image = SFSymbols.paragraph
            content.text = text.replacingOccurrences(of: Recipe.sectionHeader, with: "").trim()
            content.textColor = StyleGuide.colors.secondaryText
            content.font = StyleGuide.fonts.sectionHeader
            content.placeholder = "Section name"
            content.contentInset = 16
        } else {
            content.image = nil
            content.text = text
            content.textColor = StyleGuide.colors.primaryText
            content.placeholder = RecipeFormCell.textFieldPlaceholder(for: section)
            content.contentInset = 12
        }
        content.onChange =  { [weak self] (text) in
            let text = text.trim()
            if self?.isSectionHeader ?? false {
                self?.onChange?("\(Recipe.sectionHeader) \(text)")
            } else {
                self?.onChange?(text)
            }
        }
        content.onBeginEditing = self.onBeginEditing
        content.onEndEditing = self.onEndEditing

        switch section {
        case .title:
            content.autocapitalizationType = .words
        case .ingredients, .instructions:
            content.autocapitalizationType = .sentences
        }

        self.contentConfiguration = content
        self.selectionStyle = .none
    }

    private func buttonContentView(text: String) -> UIListContentView {
        var content =  self.defaultContentConfiguration()
        content.image = SFSymbols.addRecipe
        content.imageProperties.tintColor = StyleGuide.colors.primary
        content.text = text
        content.textProperties.color = StyleGuide.colors.primary

        let view = UIListContentView(configuration: content)
        view.backgroundColor = StyleGuide.colors.background
        return view
    }

    private func setButton(for indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else { return }
        self.selectionStyle = .default

        let itemButton = self.buttonContentView(text: Self.buttonText(for: section))
        let sectionButton = self.buttonContentView(text: "Section")

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.backgroundColor = UITableView().separatorColor
        stackView.distribution = .fillEqually
        stackView.spacing = 0.3
        stackView.addArrangedSubview(itemButton)
        stackView.addArrangedSubview(sectionButton)
        self.addPinnedSubview(stackView)

        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.onTap))
        self.addGestureRecognizer(gesture)
    }

    func set(_ info: Info, for indexPath: IndexPath) {
        switch info.style {
        case .textField:
            self.setTextField(with: info.text, for: indexPath)
        case .button:
            self.setButton(for: indexPath)
        }
    }

    @objc func onTap(sender: UITapGestureRecognizer) { 
        let taploc = sender.location(in: self)
        let sector = taploc.x < (self.frame.width / 2) ? TapLocation.item : TapLocation.section
        self.onButtonTap?(self, sector)
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

    static func buttonText(for section: Section) -> String {
        switch section {
        case .title:
            return ""
        case .ingredients:
            return "Ingredient"
        case .instructions:
            return "Instruction"
        }
    }
}
