//
//  RBBulletedListView.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/7/23.
//

import UIKit

class RBBulletedListView: UITextView {

    static let bulletSpacing: CGFloat = 12
    static let paragraphSpacing: CGFloat = 4

    init(fontSize: CGFloat) {
        super.init(frame: .zero, textContainer: nil)
        self.configure(fontSize: fontSize)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(fontSize: CGFloat) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.font = .systemFont(ofSize: fontSize)
    }

    func setItems(items: [String]) {
        var bullets: [String] = []
        for item in items {
            bullets.append("•\t\(item)")
        }
        let string = bullets.joined(separator: "\u{2029}")

        let paragraphStyle = NSMutableParagraphStyle()
        let bulletSize = NSAttributedString(string: "•", attributes: [.font: self.font!]).size()
        let itemStart = bulletSize.width + RBBulletedListView.bulletSpacing
        paragraphStyle.headIndent = itemStart
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: itemStart)]
        paragraphStyle.paragraphSpacing = RBBulletedListView.paragraphSpacing

        let attributedText = NSAttributedString(
            string: string,
            attributes: [.paragraphStyle: paragraphStyle, .font: self.font!])
        self.attributedText = attributedText
    }
}
