//
//  RecipeFormCell.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/26/23.
//

import UIKit

protocol RecipeFormCellDelegate: AnyObject {
    func textFieldDidBeginEditing(_: UUID)
    func ingredientsButtonPressed()
    func instructionsButtonPressed()
}

class RecipeFormCell: UITableViewCell {
    static let reuseID = "RecipeFormCell"

    enum Content {
        case input(UUID, String)
        case actionButton(UUID)
    }

    var section: RecipeFormVC.Section?
    var uuid: UUID?
    var textField: RBTextField?
    var actionButton: RBPlainButton?

    weak var delegate: RecipeFormCellDelegate?

    override func prepareForReuse() {
        super.prepareForReuse()

        self.textField?.removeFromSuperview()
        self.textField = nil

        self.actionButton?.removeFromSuperview()
        self.actionButton = nil
    }

    func setInput(section: RecipeFormVC.Section, uuid: UUID, text: String) {
        self.section = section
        self.uuid = uuid

        self.textField = RBTextField(placeholder: section.textFieldPlaceholder(), horizontalPadding: 20)
        self.textField?.delegate = self
        self.textField?.text = text
        self.addSubview(self.textField!)

        NSLayoutConstraint.activate([
            self.textField!.topAnchor.constraint(equalTo: self.topAnchor, constant: 1),
            self.textField!.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -1),
            self.textField!.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.textField!.trailingAnchor.constraint(equalTo: self.trailingAnchor),
        ])
    }

    func setActionButton(section: RecipeFormVC.Section, uuid: UUID) {
        self.section = section
        self.uuid = uuid

        self.actionButton = RBPlainButton(title: section.actionButtonText()!, systemImageName: "plus.circle")
        self.actionButton!.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        self.addSubview(self.actionButton!)

        NSLayoutConstraint.activate([
            self.actionButton!.topAnchor.constraint(equalTo: self.topAnchor, constant: 4),
            self.actionButton!.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -4),
            self.actionButton!.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8),
        ])
    }

    func set(section: RecipeFormVC.Section, content: Content) {
        self.contentView.isUserInteractionEnabled = false

        switch content {
        case .input(let uuid, let text):
            self.setInput(section: section, uuid: uuid, text: text)
        case .actionButton(let uuid):
            self.setActionButton(section: section, uuid: uuid)
        }
    }

    @objc func buttonPressed() {
        if let section = self.section {
            switch section {
            case .title:
                break
            case .ingredients:
                self.delegate?.ingredientsButtonPressed()
            case .instructions:
                self.delegate?.instructionsButtonPressed()
            }
        }
    }
}

extension RecipeFormCell: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.delegate?.textFieldDidBeginEditing(self.uuid!)
    }
}

extension RecipeFormCell.Content {

    static func createInput() -> RecipeFormCell.Content {
        return .input(UUID(), "")
    }

    static func createButton() -> RecipeFormCell.Content {
        return .actionButton(UUID())
    }

    func uuid() -> UUID {
        switch self  {
        case .input(let uuid, _):
            return uuid
        case .actionButton(let uuid):
            return uuid
        }
    }
}
