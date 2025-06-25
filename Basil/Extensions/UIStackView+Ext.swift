//
//  UIStackView+Ext.swift
//  Basil
//
//  Created by Ian Brault on 6/21/25.
//

import UIKit

extension UIStackView {

    func removeAllArrangedSubviews() {
        for subview in self.arrangedSubviews {
            self.removeArrangedSubview(subview)
        }
    }
}
