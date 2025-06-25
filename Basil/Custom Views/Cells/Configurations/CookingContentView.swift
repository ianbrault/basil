//
//  CookingContentView.swift
//  Basil
//
//  Created by Ian Brault on 3/22/25.
//

import UIKit

struct CookingContentConfiguration: UIContentConfiguration {

    var text: String = ""
    var selected: Bool = false

    var imageSize: CGFloat = 24
    var contentInset: CGFloat = 16
    var imageToTextPadding: CGFloat = 12

    func makeContentView() -> UIView & UIContentView {
        return CookingContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> CookingContentConfiguration {
        return self
    }
}

class CookingContentView: UIView, UIContentView {

    var configuration: UIContentConfiguration {
        didSet {
            self.configure()
        }
    }

    private let image = UIImageView()
    private let label = UILabel()

    private var paragraphStyle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 4
        style.paragraphSpacing = 10
        return style
    }

    init(configuration: CookingContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        guard let configuration = self.configuration as? CookingContentConfiguration else { return }

        self.addSubview(self.image)
        self.addSubview(self.label)

        self.image.image = configuration.selected ? SFSymbols.checkmarkSquareFill : SFSymbols.square
        self.image.tintColor = configuration.selected ? StyleGuide.colors.primary : StyleGuide.colors.secondaryText
        self.image.contentMode = .scaleAspectFill
        self.image.translatesAutoresizingMaskIntoConstraints = false

        self.label.attributedText = NSAttributedString(
            string: configuration.text,
            attributes: [.paragraphStyle: self.paragraphStyle]
        )
        self.label.numberOfLines = 0
        self.label.translatesAutoresizingMaskIntoConstraints = false

        self.image.heightAnchor.constraint(equalToConstant: configuration.imageSize).isActive = true
        self.image.topAnchor.constraint(equalTo: self.topAnchor, constant: 4).isActive = true
        self.image.centerXAnchor.constraint(
            equalTo: self.leadingAnchor, constant: (configuration.imageSize / 2) + configuration.contentInset
        ).isActive = true

        self.label.leadingAnchor.constraint(
            equalTo: self.image.centerXAnchor, constant: (configuration.imageSize / 2) + configuration.imageToTextPadding
        ).isActive = true
        self.label.trailingAnchor.constraint(
            equalTo: self.trailingAnchor, constant: -configuration.contentInset
        ).isActive = true
        self.label.topAnchor.constraint(equalTo: self.topAnchor, constant: 6).isActive = true
        self.label.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -6).isActive = true
    }
}
