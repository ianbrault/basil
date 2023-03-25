//
//  UIView+Ext.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/24/23.
//

import UIKit

extension UIView {

    func pinToEdges(of superView: UIView) {
        self.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: superView.topAnchor),
            self.leadingAnchor.constraint(equalTo: superView.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: superView.trailingAnchor),
            self.bottomAnchor.constraint(equalTo: superView.bottomAnchor),
        ])
    }
}
