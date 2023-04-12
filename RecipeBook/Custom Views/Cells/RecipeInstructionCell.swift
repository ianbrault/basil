//
//  RecipeInstructionCell.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/9/23.
//

import UIKit

class RecipeInstructionCell: UITableViewCell {
    static let reuseID = "RecipeInstructionCell"

    let instructionLabel = UITextView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(n: Int, instruction: String) {
        let string = "\(n).\t\(instruction)"

        let paragraphStyle = NSMutableParagraphStyle()
        let bulletSize = NSAttributedString(
            string: "8.",
            attributes: [.font: self.instructionLabel.font!]).size()
        let itemStart = bulletSize.width + 8
        paragraphStyle.headIndent = itemStart
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: itemStart)]
        paragraphStyle.paragraphSpacing = 6

        let attributedText = NSAttributedString(
            string: string,
            attributes: [.paragraphStyle: paragraphStyle, .font: self.instructionLabel.font!])
        self.instructionLabel.attributedText = attributedText
    }

    private func configure() {
        self.addSubview(self.instructionLabel)

        self.instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        self.instructionLabel.font = .systemFont(ofSize: 16)
        self.instructionLabel.isScrollEnabled = false
        self.instructionLabel.textContainer.lineFragmentPadding = 0
        self.instructionLabel.textContainerInset = .zero

        NSLayoutConstraint.activate([
            self.instructionLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 4),
            self.instructionLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -4),
            self.instructionLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 24),
            self.instructionLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -24),
        ])
    }
}
