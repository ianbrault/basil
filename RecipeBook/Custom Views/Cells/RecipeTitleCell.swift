//
//  RecipeTitleCell.swift
//  RecipeBook
//
//  Created by Ian Brault on 9/10/23.
//

import UIKit

class RecipeTitleCell: UITableViewCell {
    static let reuseID = "RecipeTitleCell"

    let titleLabel = RBTitleLabel(fontSize: 24)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(title: String) {
        self.titleLabel.text = title
        self.titleLabel.sizeToFit()
    }

    private func configure() {
        self.addSubview(self.titleLabel)
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.numberOfLines = 0

        NSLayoutConstraint.activate([
            self.titleLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 16),
            self.titleLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            self.titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
        ])
    }
}
