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
    var recipes: [UUID]
    var subfolders: [UUID]

    init(folderId: UUID?, name: String, recipes: [UUID] = [], subfolders: [UUID] = []) {
        self.uuid = UUID()
        self.folderId = folderId
        self.name = name
        self.recipes = recipes
        self.subfolders = subfolders
    }

    static func root() -> RecipeFolder {
        return RecipeFolder(folderId: nil, name: "Recipes")
    }

    func addRecipe(uuid: UUID) {
        self.recipes.append(uuid)
    }

    func addSubfolder(uuid: UUID) {
        self.subfolders.append(uuid)
    }

    func removeRecipe(uuid: UUID) {
        self.recipes.removeAll { $0 == uuid }
    }

    func removeSubfolder(uuid: UUID) {
        self.subfolders.removeAll { $0 == uuid }
    }

    func attributedText(namePlaceholder: String = "", isEnabled: Bool = true) -> NSAttributedString {
        let name = self.name.isEmpty ? namePlaceholder : self.name

        let imageAttachment = NSTextAttachment()
        imageAttachment.image = SFSymbols.folder?.withTintColor(isEnabled ? .systemYellow : .systemGray3)

        let padding = NSTextAttachment()
        padding.bounds = CGRect(x: 0, y: 0, width: 10, height: 0)

        let message = NSMutableAttributedString(attachment: imageAttachment)
        message.append(NSMutableAttributedString(attachment: padding))
        message.append(NSMutableAttributedString(string: name))

        return message
    }

    func update(with other: RecipeFolder) {
        self.folderId = other.folderId
        self.name = other.name
        self.recipes = other.recipes
        self.subfolders = other.subfolders
    }

    static func sort(_ this: RecipeFolder, _ that: RecipeFolder) -> Bool {
        return this.name < that.name
    }

    static func sortReverse(_ this: RecipeFolder, _ that: RecipeFolder) -> Bool {
        return !RecipeFolder.sort(this, that)
    }
}
