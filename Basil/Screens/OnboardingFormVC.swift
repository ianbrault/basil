//
//  OnboardingFormVC.swift
//  RecipeBook
//
//  Created by Ian Brault on 8/13/24.
//

import SwiftEmailValidator
import UIKit

//
// Presents a form to allow the user to register or login, depending on the provided style
// Uses the scene delegate to transfer control back to the main flow once the user info has been validated
//
class OnboardingFormVC: UITableViewController {
    static let reuseID = "OnboardingFormCell"

    enum FormStyle {
        case register
        case login
    }

    private struct Cell {
        let image: UIImage?
        var text: String
        let placeholder: String
        let contentType: UITextContentType?
        let keyboardType: UIKeyboardType
        let isSecure: Bool
        var hasError: Bool

        init(
            image: UIImage?,
            placeholder: String,
            contentType: UITextContentType? = nil,
            keyboardType: UIKeyboardType = .default,
            isSecure: Bool = false
        ) {
            self.image = image
            self.text = ""
            self.placeholder = placeholder
            self.contentType = contentType
            self.keyboardType = keyboardType
            self.isSecure = isSecure
            self.hasError = false
        }
    }

    private var style: FormStyle
    private var onCompletion: ((BasilError?) -> Void)?

    private var button: Button!
    private var cells: [Cell]!

    private let emailIndex = IndexPath(row: 0, section: 0)
    private let passwordIndex = IndexPath(row: 1, section: 0)
    private let confirmPasswordIndex = IndexPath(row: 2, section: 0)

    private let buttonHeight: CGFloat = 54
    private let insets = UIEdgeInsets(top: 0, left: 40, bottom: 16, right: 40)

    init(_ style: FormStyle, onCompletion: @escaping (BasilError?) -> Void) {
        self.style = style
        self.onCompletion = onCompletion
        switch style {
        case .register:
            self.button = Button(title: "Register")
            self.cells = [
                Cell(image: SFSymbols.email, placeholder: "Email", contentType: .username, keyboardType: .emailAddress),
                Cell(image: SFSymbols.password, placeholder: "Password", contentType: .newPassword, isSecure: true),
                Cell(image: SFSymbols.confirmPassword, placeholder: "Confirm Password", contentType: .newPassword, isSecure: true),
            ]
        case .login:
            self.button = Button(title: "Login")
            self.cells = [
                Cell(image: SFSymbols.email, placeholder: "Email", contentType: .username, keyboardType: .emailAddress),
                Cell(image: SFSymbols.password, placeholder: "Password", contentType: .password, isSecure: true),
            ]
        }
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureViewController()
        self.configureTableView()
        self.configureButton()
    }

    private func configureViewController() {
        self.view.backgroundColor = .secondarySystemGroupedBackground

        switch style {
        case .register:
            self.title = "Create Account"
        case .login:
            self.title = "Log in"
        }

        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.navigationBar.tintColor = StyleGuide.colors.primary

        let appearance = UINavigationBarAppearance()
        appearance.largeTitleTextAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 32, weight: .bold),
        ]
        self.navigationController?.navigationBar.standardAppearance = appearance
    }

    private func configureTableView() {
        self.tableView.contentInset.top = 16
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.separatorInsetReference = .fromAutomaticInsets
        self.tableView.removeExcessCells()

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: OnboardingFormVC.reuseID)
    }

    private func configureButton() {
        self.view.addPinnedSubview(self.button, height: self.buttonHeight, insets: self.insets, keyboardBottom: true, noTop: true)
        self.button.addTarget(self, action: #selector(self.onSubmit), for: .touchUpInside)
    }

    func validateForm() -> Bool {
        var valid = true

        // check if any of the fields are empty
        for i in 0..<self.cells.count {
            if i == self.confirmPasswordIndex.row && self.style != .register {
                continue
            }
            self.cells[i].hasError = self.cells[i].text.isEmpty
            if self.cells[i].hasError {
                valid = false
            }
        }

        // validate the email address
        if !EmailSyntaxValidator.correctlyFormatted(self.cells[self.emailIndex.row].text) {
            self.cells[self.emailIndex.row].hasError = true
            valid = false
        }

        // check if the password and confirm password fields match
        if self.style == .register {
            if self.cells[self.passwordIndex.row].text != self.cells[self.confirmPasswordIndex.row].text {
                self.presentErrorAlert(.passwordsDoNotMatch)
                valid = false
            }
        }

        self.tableView.reloadSections(IndexSet([0]), with: .automatic)
        return valid
    }

    @objc func onSubmit(_ action: UIAction) {
        guard self.validateForm() else { return }
        let email = self.cells[self.emailIndex.row].text
        let password = self.cells[self.passwordIndex.row].text

        // common response handler for login/register endpoints
        let handler: NetworkManager.BodyHandler<API.AuthenticationResponse> = { [weak self] (result) in
            var err: BasilError? = nil
            switch result {
            case .success(let info):
                // Add the password to the keychain
                do {
                    try KeychainManager.setCredentials(email: email, password: password)
                } catch {
                    err = error as? BasilError
                }
                // Store the user info to the app state
                State.manager.addUserInfo(info: info)
                // Set the offline read-only mode flag until authentication has completed successfully
                State.manager.readOnly = true
                // Open the WebSocket connection with the server
                SocketManager.shared.connect(userId: info.id, token: info.token)
            case .failure(let error):
                err = error
            }
            self?.dismissLoadingView()
            self?.onCompletion?(err)
        }

        self.showLoadingView()
        switch self.style {
        case .register:
            NetworkManager.createUser(
                email: email, password: password,
                root: State.manager.root, recipes: State.manager.recipes, folders: State.manager.folders,
                handler: handler
            )
        case .login:
            NetworkManager.authenticate(email: email, password: password, handler: handler)
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.style {
        case .register:
            return 3
        case .login:
            return 2
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: OnboardingFormVC.reuseID)!
        let info = self.cells[indexPath.row]

        var content = TextFieldContentConfiguration()
        content.image = info.image
        content.tintColor = info.hasError ? StyleGuide.colors.error : StyleGuide.colors.primary
        content.text = info.text
        content.placeholder = info.placeholder
        content.contentType = (self.style == .register && info.contentType == .password) ? .newPassword : info.contentType
        content.isSecureTextEntry = info.isSecure

        content.onChange =  { [weak self] (text, sender) in
            guard let text else { return }
            if let cell = sender.next(ofType: UITableViewCell.self) {
                if let i = tableView.indexPath(for: cell) {
                    self?.cells[i.row].text = text
                }
            }
        }

        cell.contentConfiguration = content
        cell.separatorInset.left = content.contentInset + content.imageSize

        return cell
    }
}
