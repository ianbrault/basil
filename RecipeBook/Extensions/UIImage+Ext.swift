//
//  UIImage+Ext.swift
//  RecipeBook
//
//  Created by Ian Brault on 12/1/23.
//

import UIKit

extension UIImage {

    func imageWith(newSize: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let image = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return image.withRenderingMode(.alwaysOriginal)
    }
}
