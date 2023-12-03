//
//  RBCellTextField.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/25/23.
//

import UIKit

class RBCellTextField: UITextField {

    // adds internal padding
    let textPadding: UIEdgeInsets!

    init(placeholder: String?, verticalPadding: CGFloat = 6, horizontalPadding: CGFloat = 12) {
        self.textPadding = UIEdgeInsets(top: verticalPadding, left: horizontalPadding, bottom: verticalPadding, right: horizontalPadding)
        super.init(frame: .zero)
        self.configure(placeholder: placeholder)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.textRect(forBounds: bounds)
        return rect.inset(by: self.textPadding)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.editingRect(forBounds: bounds)
        return rect.inset(by: self.textPadding)
    }

    private func configure(placeholder: String?) {
        self.translatesAutoresizingMaskIntoConstraints = false

        self.backgroundColor = .tertiarySystemBackground
        self.textColor = .label
        self.tintColor = .label
        self.font = UIFont.systemFont(ofSize: 16)

        self.autocorrectionType = .yes
        self.returnKeyType = .go
        self.clearButtonMode = .whileEditing
        if let placeholder {
            self.placeholder = placeholder
        }
    }
}
