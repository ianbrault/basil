//
//  RecipeFolder.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/29/23.
//

import UIKit

class RecipeFolder: Codable {
    let uuid: UUID
    var folderId: UUID?
    var name: String
    var items: [UUID]

    init(folderId: UUID?, name: String, items: [UUID] = []) {
        self.uuid = UUID()
        self.folderId = folderId
        self.name = name
        self.items = items
    }

    static func root() -> RecipeFolder {
        return RecipeFolder(folderId: nil, name: "Recipes")
    }

    func addItem(uuid: UUID) {
        self.items.append(uuid)
    }

    func removeItem(uuid: UUID) {
        self.items.removeAll { $0 == uuid }
    }

    func attributedText() -> NSAttributedString {
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = SFSymbols.folder?.withTintColor(.systemYellow)

        let padding = NSTextAttachment()
        padding.bounds = CGRect(x: 0, y: 0, width: 10, height: 0)

        let message = NSMutableAttributedString(attachment: imageAttachment)
        message.append(NSMutableAttributedString(attachment: padding))
        message.append(NSMutableAttributedString(string: self.name))

        return message
    }

    static func sort(_ this: RecipeFolder, _ that: RecipeFolder) -> Bool {
        return this.name < that.name
    }
}
