//
//  ShareViewController.swift
//  ShareNotes
//
//  Created by Ian Brault on 6/27/25.
//

import UIKit
import UniformTypeIdentifiers

//
// UI for sharing files/text that can be imported as a recipe
// This view is a copy of RecipeFormVC with a few tweaks
//
class ShareViewController: UIViewController {

    private let navigationBar = UINavigationBar()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let label = UILabel()

    private var loadError: BasilError? = nil

    private static let titleFont = UIFont.systemFont(ofSize: StyleGuide.fonts.navigationBar.pointSize * 0.8, weight: .bold)
    private static let paragraphSpacing: CGFloat = 8
    private static let sectionParagraphSpacing: CGFloat = 12
    private static var paragraphStyle: NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = Self.paragraphSpacing
        return paragraphStyle
    }
    private static var sectionParagraphStyle: NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = Self.sectionParagraphSpacing
        return paragraphStyle
    }

    private var credentials: KeychainManager.Credentials? = nil
    private var recipe: Recipe? = nil

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let error = self.loadError {
            self.presentError(error)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = StyleGuide.colors.background
        self.configureNavigationBar()
        self.configureLabel()
        self.loadCredentials()
        self.loadFromExtension()
    }

    private func presentError(_ error: BasilError) {
        let alert = UIAlertController(title: error.title, message: error.message, preferredStyle: .alert)
        alert.view.tintColor = StyleGuide.colors.primary
        alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: { [weak self] (_) in
            self?.close()
        }))
        self.present(alert, animated: true)
    }

    private func configureNavigationBar() {
        self.view.addSubview(self.navigationBar)
        self.navigationBar.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 54)
        self.navigationBar.tintColor = StyleGuide.colors.primary

        self.navigationItem.title = "Import Recipe"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.close))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.save))

        self.navigationBar.items = [self.navigationItem]
    }

    private func configureLabel() {
        self.label.font = StyleGuide.fonts.body
        self.label.numberOfLines = 0

        let insets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        self.view.addPinnedSubview(self.scrollView, insets: insets, safeAreaBottom: true, noTop: true)
        self.scrollView.topAnchor.constraint(equalTo: self.navigationBar.bottomAnchor, constant: insets.top).isActive = true
        self.scrollView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)

        self.scrollView.addSubview(self.contentView)
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.topAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.topAnchor).isActive = true
        self.contentView.bottomAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.bottomAnchor).isActive = true
        self.contentView.leadingAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.leadingAnchor).isActive = true
        self.contentView.trailingAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.trailingAnchor).isActive = true
        self.contentView.widthAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.widthAnchor).isActive = true

        let textInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        self.contentView.addPinnedSubview(self.label, insets: textInsets)
    }

    private func loadCredentials() {
        do {
            self.credentials = try KeychainManager.getCredentials()
        } catch {
            self.loadError = error as? BasilError ?? .keychainError(errSecItemNotFound)
        }
    }

    private func loadFromExtension() {
        guard let item = self.extensionContext?.inputItems.first as? NSExtensionItem,
              let provider = item.attachments?.first as? NSItemProvider,
              provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier)
        else {
            self.loadError = .extensionError("Extension is missing or has an invalid type. Accepted: plain text")
            return
        }

        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { [weak self] (item, error) in
            if let error {
                self?.loadError = .extensionError(error.localizedDescription)
            } else if let text = item as? String {
                switch NoteParser.shared.parse(text: text) {
                case .success(let recipe):
                    self?.recipe = recipe
                    DispatchQueue.main.async {
                        self?.label.attributedText = Self.renderRecipe(recipe)
                    }
                case .failure(let error):
                    self?.loadError = error
                }
            } else {
                self?.loadError = .extensionError("Extension is missing or has an invalid type. Accepted: plain text")
            }
        }
    }

    private static func renderRecipe(_ recipe: Recipe) -> NSAttributedString {
        let output = NSMutableAttributedString()
        let title = NSAttributedString(
            string: "\(recipe.title)\n",
            attributes: [.font: Self.titleFont, .paragraphStyle: self.paragraphStyle]
        )
        let ingredients = NSAttributedString(
            string: "Ingredients:\n",
            attributes: [.font: StyleGuide.fonts.sectionHeader, .paragraphStyle: self.sectionParagraphStyle]
        )
        let instructions = NSAttributedString(
            string: "Instructions:\n",
            attributes: [.font: StyleGuide.fonts.sectionHeader, .paragraphStyle: self.sectionParagraphStyle]
        )
        output.append(title)
        output.append(ingredients)
        for ingredient in recipe.ingredients {
            let text = ingredient.toString()
            if text.starts(with: Recipe.sectionHeader) {
                let section = text.replacingOccurrences(of: Recipe.sectionHeader, with: "").trim()
                let attrText = NSAttributedString(
                    string: "\(section)\n",
                    attributes: [.font: StyleGuide.fonts.sectionHeader, .paragraphStyle: self.paragraphStyle]
                )
                output.append(attrText)
            } else {
                let attrText = ListContentView.unorderedString(
                    ingredient.toString(),
                    font: StyleGuide.fonts.body, paragraphSpacing: Self.paragraphSpacing
                )
                output.append(attrText)
                output.append(NSAttributedString(string: "\n"))
            }
        }
        output.append(instructions)
        var row = 0
        for (i, instruction) in recipe.instructions.enumerated() {
            if instruction.starts(with: Recipe.sectionHeader) {
                row = 0
                let section = instruction.replacingOccurrences(of: Recipe.sectionHeader, with: "").trim()
                let attrText = NSAttributedString(
                    string: "\(section)\n",
                    attributes: [.font: StyleGuide.fonts.sectionHeader, .paragraphStyle: self.paragraphStyle]
                )
                output.append(attrText)
            } else {
                row += 1
                let text = ListContentView.orderedString(
                    instruction, row: row,
                    font: StyleGuide.fonts.body, paragraphSpacing: Self.paragraphSpacing
                )
                output.append(text)
                if i + 1 < recipe.instructions.count {
                    output.append(NSAttributedString(string: "\n"))
                }
            }
        }
        return NSAttributedString(attributedString: output)
    }

    private func addRecipeAndPushUpdate(response info: API.AuthenticationResponse) {
        guard let recipe = self.recipe, let root = info.root else { return }
        // find the root folder and add the new recipe
        guard let rootFolder = info.folders.first(where: { $0.uuid == root }) else {
            self.presentError(.missingItem(.folder, root))
            return
        }
        rootFolder.recipes.append(recipe.uuid)
        // then add the new recipe to the recipe list
        var recipes = info.recipes
        recipe.folderId = root
        recipes.append(recipe)
        // and finally push the updated state to the server
        NetworkManager.pushUpdate(userId: info.id, token: info.token, root: root, recipes: recipes, folders: info.folders) { [weak self] (error) in
            if let error {
                self?.presentError(error)
            } else {
                self?.close()
            }
        }
    }

    @objc func save() {
        guard let credentials = self.credentials else {
            self.presentError(.keychainError(errSecItemNotFound))
            return
        }
        self.showLoadingView()
        // if the user is logged in, connect to the server and push the update
        NetworkManager.authenticate(email: credentials.email, password: credentials.password) { [weak self] (result) in
            switch result {
            case .success(let info):
                self?.addRecipeAndPushUpdate(response: info)
            case .failure(let error):
                self?.presentError(error)
            }
        }
    }

    @objc func close() {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    @objc func dismissKeyboard(_ action: UIAction) {
        self.view.endEditing(true)
    }
}
