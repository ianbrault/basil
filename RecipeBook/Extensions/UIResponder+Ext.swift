//
//  UIResponder+Ext.swift
//  RecipeBook
//
//  Created by Ian Brault on 8/16/24.
//

import UIKit

extension UIResponder {

    func next<T:UIResponder>(ofType: T.Type) -> T? {
        let r = self.next
        if let r = r as? T ?? r?.next(ofType: T.self) {
            return r
        } else {
            return nil
        }
    }
}
