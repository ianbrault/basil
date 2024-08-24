//
//  Data+Ext.swift
//  RecipeBook
//
//  Created by Ian Brault on 8/23/24.
//

import Foundation

extension Data {

    var prettyPrintedJSONString: String? {
        if let jsonObject = try? JSONSerialization.jsonObject(with: self, options: []) {
            if let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]) {
                if let prettyJSON = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                    return prettyJSON as String
                }
            }
        }
        return nil
    }
}
