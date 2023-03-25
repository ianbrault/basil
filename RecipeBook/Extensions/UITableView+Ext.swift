//
//  UITableView+Ext.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/24/23.
//

import UIKit

extension UITableView {

    func removeExcessCells() {
        tableFooterView = UIView(frame: .zero)
    }
}
