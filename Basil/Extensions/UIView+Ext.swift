//
//  UIView+Ext.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/24/23.
//

import UIKit

extension UIView {

    func addPinnedSubview(
        _ subview: UIView,
        height: CGFloat? = nil,
        insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
        safeAreaTop: Bool = false,
        safeAreaBottom: Bool = false,
        keyboardBottom: Bool = false,
        noTop: Bool = false,
        noBottom: Bool = false,
    ) {
        self.addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false

        subview.leadingAnchor.constraint(
            equalTo: self.leadingAnchor, constant: insets.left
        ).isActive = true
        subview.trailingAnchor.constraint(
            equalTo: self.trailingAnchor, constant: -1.0 * insets.right
        ).isActive = true

        if !noTop {
            if safeAreaTop {
                subview.topAnchor.constraint(
                    equalTo: self.safeAreaLayoutGuide.topAnchor, constant: insets.top
                ).isActive = true
            } else {
                subview.topAnchor.constraint(
                    equalTo: self.topAnchor, constant: insets.top
                ).isActive = true
            }
        }

        if !noBottom {
            if safeAreaBottom {
                subview.bottomAnchor.constraint(
                    equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -1.0 * insets.bottom
                ).isActive = true
            } else if keyboardBottom {
                subview.bottomAnchor.constraint(
                    equalTo: self.keyboardLayoutGuide.topAnchor, constant: -1.0 * insets.bottom
                ).isActive = true
            } else {
                subview.bottomAnchor.constraint(
                    equalTo: self.bottomAnchor, constant: -1.0 * insets.bottom
                ).isActive = true
            }
        }

        if let height {
            subview.heightAnchor.constraint(equalToConstant: height).isActive = true
        }
    }
}
