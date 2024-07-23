//
//  UIColor+Ext.swift
//  RecipeBook
//
//  Created by Ian Brault on 7/23/24.
//

import UIKit

extension UIColor {

    static var paleYellow: UIColor {
        var hue: CGFloat = 0
        var brightness: CGFloat = 0
        UIColor.systemYellow.getHue(&hue, saturation: nil, brightness: &brightness, alpha: nil)
        return UIColor(hue: hue, saturation: 0.15, brightness: brightness, alpha: 1.0)
    }

    static var darkYellow: UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        UIColor.systemYellow.getHue(&hue, saturation: &saturation, brightness: nil, alpha: nil)
        return UIColor(hue: hue, saturation: saturation, brightness: 0.4, alpha: 1.0)
    }
}
