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
class OnboardingFormVC: UIViewController {
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
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var button: RBButton!
    private var cells: [Cell]!

    private let emailIndex = IndexPath(row: 0, section: 0)
    private let passwordIndex = IndexPath(row: 1, section: 0)
    private let confirmPasswordIndex = IndexPath(row: 2, section: 0)

    private let buttonHeight: CGFloat = 54
    private let insets = UIEdgeInsets(top: 0, left: 40, bottom: 16, right: 40)

    init(_ style: FormStyle) {
        self.style = style
        switch style {
        case .register:
            self.button = RBButton(title: "Register")
            self.cells = [
                Cell(image: SFSymbols.email, placeholder: "Email", contentType: .username, keyboardType: .emailAddress),
                Cell(image: SFSymbols.password, placeholder: "Password", contentType: .newPassword, isSecure: true),
                Cell(image: SFSymbols.confirmPassword, placeholder: "Confirm Password", contentType: .newPassword, isSecure: true),
            ]
        case .login:
            self.button = RBButton(title: "Login")
            self.cells = [
                Cell(image: SFSymbols.email, placeholder: "Email", contentType: .username, keyboardType: .emailAddress),
                Cell(image: SFSymbols.password, placeholder: "Password", contentType: .password, isSecure: true),
            ]
        }
        super.init(nibName: nil, bundle: nil)
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
    }

    private func configureTableView() {
        self.view.addSubview(self.tableView)

        self.tableView.frame = self.view.bounds
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.contentInset.top = 16
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.separatorInsetReference = .fromAutomaticInsets
        self.tableView.removeExcessCells()

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: OnboardingFormVC.reuseID)
    }

    private func configureButton() {
        self.view.addSubview(self.button)

        self.button.addTarget(self, action: #selector(self.onSubmit), for: .touchUpInside)

        self.button.pinToSides(of: self.view, insets: self.insets)
        self.button.bottomAnchor.constraint(equalTo: self.view.keyboardLayoutGuide.topAnchor, constant: -self.insets.bottom).isActive = true
        self.button.heightAnchor.constraint(equalToConstant: self.buttonHeight).isActive = true
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
        // hash the password before sending to the server
        var hashedPassword: String
        switch hashPassword(password) {
        case .success(let hash):
            hashedPassword = hash.base64EncodedString()
        case .failure(let error):
            self.presentErrorAlert(error)
            return
        }

        var handler: (String, String, @escaping API.BodyHandler<API.UserInfo>) -> (Void)
        switch self.style {
        case .register:
            handler = API.register
        case .login:
            handler = API.login
        }

        self.showLoadingView()
        handler(email, hashedPassword) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let userInfo):
                    // store the user info to the app state and transition to the normal flow
                    State.manager.addUserInfo(info: userInfo)
                    if let delegate = self?.view.window?.windowScene?.delegate as? SceneDelegate {
                        delegate.sceneDidAddUser()
                    }
                case .failure(let error):
                    self?.presentErrorAlert(error)
                }
            }
            self?.dismissLoadingView()
        }
    }
}

extension OnboardingFormVC: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.style {
        case .register:
            return 3
        case .login:
            return 2
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return StyleGuide.tableCellHeight
    }
}
