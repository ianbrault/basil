//
//  ListContentView.swift
//  RecipeBook
//
//  Created by Ian Brault on 8/17/24.
//

import UIKit

struct ListContentConfiguration: UIContentConfiguration {

    enum Style {
        case ordered
        case unordered
    }

    var style: Style
    var text: String = ""
    var row: Int = 0

    var contentInset = UIEdgeInsets(top: 5, left: 24, bottom: 5, right: 24)

    func makeContentView() -> UIView & UIContentView {
        return ListContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> ListContentConfiguration {
        return self
    }
}

class ListContentView: UIView, UIContentView {

    var configuration: UIContentConfiguration {
        didSet {
            self.configure()
        }
    }

    private let label = UILabel()

    init(configuration: ListContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func orderedString(_ text: String, row: Int) -> NSAttributedString {
        let string = "\(row).\t\(text)"
        let bulletSize = NSAttributedString(
            string: "8.",
            attributes: [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize)]
        ).size()
        let itemStart = bulletSize.width + 10

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = itemStart
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: itemStart)]
        paragraphStyle.lineSpacing = 4
        paragraphStyle.paragraphSpacing = 10

        return NSAttributedString(
            string: string,
            attributes: [.paragraphStyle: paragraphStyle]
        )
    }

    private func unorderedString(_ text: String) -> NSAttributedString {
        let string = "•\t\(text)"
        let bulletSize = NSAttributedString(
            string: "•",
            attributes: [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize)]
        ).size()
        let itemStart = bulletSize.width + 12

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = itemStart
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: itemStart)]
        paragraphStyle.lineSpacing = 4
        paragraphStyle.paragraphSpacing = 10

        return NSAttributedString(
            string: string,
            attributes: [.paragraphStyle: paragraphStyle]
        )
    }

    private func configure() {
        guard let configuration = self.configuration as? ListContentConfiguration else { return }

        self.addSubview(self.label)

        self.label.numberOfLines = 0
        switch configuration.style {
        case .ordered:
            self.label.attributedText = self.orderedString(configuration.text, row: configuration.row)
        case .unordered:
            self.label.attributedText = self.unorderedString(configuration.text)
        }

        self.label.pinToEdges(of: self, insets: configuration.contentInset)
    }
}
