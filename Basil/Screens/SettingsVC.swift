//
//  SettingsVC.swift
//  RecipeBook
//
//  Created by Ian Brault on 8/24/24.
//

import UIKit

//
// Window containing user settings
// Presented as a form sheet
//
// Future features:
// change email
// change password
//
class SettingsVC: UITableViewController {
    static let reuseID = "SettingsCell"

    struct Section {
        let cell: (inout UIListContentConfiguration) -> Void
        let action: (() -> Void)?
    }

    private var sections: [[Section]] = []

    init() {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureNavigationController()
        self.configureTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.registerSections()
    }

    private func registerSections() {
        if State.manager.userAuthenticated {
            self.sections = [
                [
                    Section(
                        cell: { (content: inout UIListContentConfiguration) in
                            content.text = State.manager.userEmail
                            content.textProperties.color = StyleGuide.colors.primaryText
                            content.image = nil
                        },
                        action: nil
                    )
                ],
                [
                    Section(
                        cell: { (content: inout UIListContentConfiguration) in
                            content.text = "Sign out"
                            content.textProperties.color = StyleGuide.colors.error
                            content.image = SFSymbols.logout
                            content.imageProperties.tintColor = StyleGuide.colors.error
                        },
                        action: self.logoutAction
                    ),
                    Section(
                        cell: { (content: inout UIListContentConfiguration) in
                            content.text = "Delete account"
                            content.textProperties.color = StyleGuide.colors.error
                            content.image = SFSymbols.trash
                            content.imageProperties.tintColor = StyleGuide.colors.error
                        },
                        action: self.deleteAccountAction
                    )
                ]
            ]
        } else {
            self.sections = [
                [
                    Section(
                        cell: { (content: inout UIListContentConfiguration) in
                            content.text = "Log in"
                            content.textProperties.color = StyleGuide.colors.primaryText
                            content.image = nil
                        },
                        action: self.loginAction
                    ),
                    Section(
                        cell: { (content: inout UIListContentConfiguration) in
                            content.text = "Create an account"
                            content.textProperties.color = StyleGuide.colors.primaryText
                            content.image = nil
                        },
                        action: self.registerAction
                    )
                ]
            ]
        }
    }

    private func configureNavigationController() {
        self.title = "Settings"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.navigationBar.tintColor = StyleGuide.colors.primary
        self.navigationController?.setNavigationBarHidden(false, animated: true)

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

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: SettingsVC.reuseID)
        self.tableView.setContentOffset(CGPoint(x: 0, y: -100), animated: true)
    }

    private func userAdded(_ error: BasilError?) {
        if let error {
            self.presentErrorAlert(error)
        } else {
            DispatchQueue.main.async {
                self.registerSections()
                self.tableView.reloadData()
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    private func userRemoved(_ error: BasilError?) {
        if let error {
            self.presentErrorAlert(error)
        } else {
            // Disconnect from the server
            SocketManager.shared.disconnect()
            // Clear the stored password from the keychain
            do {
                try KeychainManager.deleteCredentials()
            } catch {
                self.presentErrorAlert(error as! BasilError)
            }
            // Clear all stored user state
            State.manager.clearUserInfo()
            State.manager.readOnly = false
            State.manager.userChanged = true
            // Then reload the settings view
            DispatchQueue.main.async {
                self.registerSections()
                self.tableView.reloadData()
            }
        }
    }

    private func loginAction() {
        // NOTE: logging in will wipe away any recipes/folders that were created before logging in
        // TODO: add an option to import the recipes/folders into the account after logging in
        let vc = OnboardingFormVC(.login) { [weak self] (error) in
            State.manager.userChanged = error == nil
            self?.userAdded(error)
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }

    private func registerAction() {
        let vc = OnboardingFormVC(.register, onCompletion: self.userAdded)
        self.navigationController?.pushViewController(vc, animated: true)
    }

    private func logoutAction() {
        let message = "Logging out will remove any saved recipes until you log back in to your account. " +
        "Are you sure you want to continue?"
        let warning = WarningAlert(message) { [weak self] () in
            self?.userRemoved(nil)
        }
        self.present(warning, animated: true)
    }

    private func deleteAccountAction() {
        let message = "This action is irreversible, are you sure you want to continue? " +
        "Enter your password to confirm."
        let alert = TextFieldAlert(
            title: "Delete your Account", message: message, placeholder: "Password",
            confirmText: "Delete", destructive: true
        ) { [weak self](password) in
            self?.showLoadingView()
            NetworkManager.deleteUser(email: State.manager.userEmail, password: password) { (error) in
                self?.dismissLoadingView()
                self?.userRemoved(error)
            }
        }
        alert.isSecureTextEntry = true
        self.present(alert, animated: true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return StyleGuide.tableCellHeight
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sections[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsVC.reuseID)!
        var content = cell.defaultContentConfiguration()
        self.sections[indexPath.section][indexPath.row].cell(&content)
        cell.contentConfiguration = content
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.sections[indexPath.section][indexPath.row].action?()
    }
}
