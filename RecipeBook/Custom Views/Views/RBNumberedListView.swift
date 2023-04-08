//
//  RBNumberedListView.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/7/23.
//

import UIKit

class RBNumberedListView: UIStackView {

    var font: UIFont!

    class ItemView: UIView {

        init(number: Int, text: String, font: UIFont) {
            super.init(frame: .zero)
            self.configure(number: number, text: text, font: font)
        }

        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func configure(number: Int, text: String, font: UIFont) {
            self.translatesAutoresizingMaskIntoConstraints = false
            let numberWidth: CGFloat = 20
            let spacing: CGFloat = 8

            let textLabel = RBBodyLabel(fontSize: font.pointSize)
            textLabel.translatesAutoresizingMaskIntoConstraints = false
            textLabel.text = text
            textLabel.numberOfLines = 0
            self.addSubview(textLabel)
            NSLayoutConstraint.activate([
                textLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                textLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: numberWidth + spacing),
                textLabel.topAnchor.constraint(equalTo: self.topAnchor),
                self.heightAnchor.constraint(equalTo: textLabel.heightAnchor),
            ])

            let numberLabel = RBBodyLabel(fontSize: font.pointSize)
            numberLabel.text = "\(number)."
            numberLabel.textAlignment = .right
            self.addSubview(numberLabel)
            NSLayoutConstraint.activate([
                numberLabel.widthAnchor.constraint(equalToConstant: numberWidth),
                numberLabel.trailingAnchor.constraint(equalTo: textLabel.leadingAnchor, constant: -spacing),
            ])
        }
    }

    init(fontSize: CGFloat) {
        super.init(frame: .zero)
        self.configure(fontSize: fontSize)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(fontSize: CGFloat) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.axis = .vertical
        self.font = .systemFont(ofSize: fontSize)
        self.spacing = 6
    }

    func setItems(items: [String]) {
        for (n, item) in items.enumerated() {
            let itemView = ItemView(number: n + 1, text: item, font: self.font)
            self.addArrangedSubview(itemView)
            NSLayoutConstraint.activate([
                itemView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                itemView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            ])
        }
    }
}
