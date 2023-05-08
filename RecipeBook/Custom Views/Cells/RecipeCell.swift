//
//  RecipeCell.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/24/23.
//

import UIKit

class RecipeCell: UITableViewCell {
    static let reuseID = "RecipeCell"

    let titleLabel = RBBodyLabel(fontSize: 16)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setRecipe(recipe: Recipe) {
        self.titleLabel.text = recipe.title
    }

    private func setFolder(folder: RecipeFolder) {
        self.accessoryType = .disclosureIndicator

        let imageAttachment = NSTextAttachment()
        imageAttachment.image = SFSymbols.folder?.withTintColor(.systemYellow)

        let padding = NSTextAttachment()
        padding.bounds = CGRect(x: 0, y: 0, width: 10, height: 0)

        let message = NSMutableAttributedString(attachment: imageAttachment)
        message.append(NSMutableAttributedString(attachment: padding))
        message.append(NSMutableAttributedString(string: folder.name))

        self.titleLabel.attributedText = NSMutableAttributedString(attributedString: message)
    }

    func set(item: RecipeItem) {
        switch item {
        case .recipe(let recipe):
            self.setRecipe(recipe: recipe)
        case .folder(let folder):
            self.setFolder(folder: folder)
        }
    }

    private func configure() {
        self.addSubview(self.titleLabel)

        self.titleLabel.lineBreakMode = .byTruncatingTail

        NSLayoutConstraint.activate([
            self.titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 24),
            self.titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -45),
            self.titleLabel.heightAnchor.constraint(equalToConstant: 24),
        ])
    }
}
