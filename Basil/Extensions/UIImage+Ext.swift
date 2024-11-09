//
//  UIImage+Ext.swift
//  RecipeBook
//
//  Created by Ian Brault on 12/1/23.
//

import UIKit

extension UIImage {

    func getImageSize(size: CGFloat) -> CGSize {
        let scaleFactor = size / self.size.width
        let height = self.size.height * scaleFactor
        return CGSize(width: size, height: height)
    }

    func imageWith(newSize: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let image = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return image.withRenderingMode(.alwaysOriginal)
    }
}
