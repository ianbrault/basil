//
//  UIView+Ext.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/24/23.
//

import UIKit

extension UIView {

    func addShadow() {
        self.layer.shadowColor = UIColor.gray.cgColor
        self.layer.shadowOpacity = 0.2
        self.layer.shadowOffset = CGSize(width: 2, height: 2)
        self.layer.shadowRadius = 5
        self.layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
    }

    func pinToEdges(of superView: UIView, insets: UIEdgeInsets? = nil) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.leadingAnchor.constraint(equalTo: superView.leadingAnchor, constant: insets?.left ?? 0).isActive = true
        self.trailingAnchor.constraint(equalTo: superView.trailingAnchor, constant: -(insets?.right ?? 0)).isActive = true
        self.topAnchor.constraint(equalTo: superView.topAnchor, constant: insets?.top ?? 0).isActive = true
        self.bottomAnchor.constraint(equalTo: superView.bottomAnchor, constant: -(insets?.bottom ?? 0)).isActive = true
    }

    func pinToSides(of superView: UIView, insets: UIEdgeInsets? = nil) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.leadingAnchor.constraint(equalTo: superView.leadingAnchor, constant: insets?.left ?? 0).isActive = true
        self.trailingAnchor.constraint(equalTo: superView.trailingAnchor, constant: -(insets?.right ?? 0)).isActive = true
    }
}
