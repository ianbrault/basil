//
//  NSTextAttachment+Ext.swift
//  RecipeBook
//
//  Created by Ian Brault on 8/23/24.
//

import UIKit

extension NSTextAttachment {

    func setImageHeight(height: CGFloat) {
        guard let image = self.image else { return }
        let ratio = image.size.width / image.size.height
        self.bounds = CGRect(x: self.bounds.origin.x, y: self.bounds.origin.y, width: ratio * height, height: height)
    }
}
