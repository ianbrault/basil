//
//  RBPlainButton.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/25/23.
//

import UIKit

class RBPlainButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience init(title: String, systemImageName: String? = nil) {
        self.init(frame: .zero)
        self.set(title: title, systemImageName: systemImageName)
    }

    private func configure() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.configuration = .plain()
    }

    final func set(title: String, systemImageName: String?) {
        self.configuration?.title = title
        self.configuration?.buttonSize = .mini

        if let systemImageName {
            self.configuration?.image = UIImage(systemName: systemImageName)
            self.configuration?.imagePadding = 6
            self.configuration?.imagePlacement = .leading
        }
    }
}
