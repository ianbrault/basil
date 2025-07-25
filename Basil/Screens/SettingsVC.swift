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
    static let switchReuseID = "SettingsCell__Switch"

    typealias CellFactory = (UITableViewCell) -> UIContentConfiguration
    typealias CellAction = () -> Void

    struct Section {
        let header: String?
        let cells: [Cell]
    }

    struct Cell {
        let factory: CellFactory
        let action: CellAction?
        let reuseId: String

        init(factory: @escaping CellFactory, action: CellAction? = nil, reuseId: String = SettingsVC.reuseID) {
            self.factory = factory
            self.action = action
            self.reuseId = reuseId
        }
    }

    private var sections: [Section] = []

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
        self.sections = State.manager.userAuthenticated ? self.authorizedSections() : self.unauthorizedSections()
    }

    static func defaultCell(
        _ cell: UITableViewCell,
        text: String, textColor: UIColor = StyleGuide.colors.primaryText,
        image: UIImage? = nil, imageColor: UIColor = StyleGuide.colors.primary,
    ) -> UIContentConfiguration {
        var content = cell.defaultContentConfiguration()
        content.text = text
        content.textProperties.color = textColor
        content.image = image
        content.imageProperties.tintColor = imageColor
        return content
    }

    static func destructiveCell(_ cell: UITableViewCell, text: String, image: UIImage? = nil) -> UIContentConfiguration {
        var content = cell.defaultContentConfiguration()
        content.text = text
        content.textProperties.color = StyleGuide.colors.error
        content.image = image
        content.imageProperties.tintColor = StyleGuide.colors.error
        return content
    }

    private func unauthorizedSections() -> [Section] {
        return [
            Section(
                header: nil,
                cells: [
                    Cell(factory: { Self.defaultCell($0, text: "Sign In") }, action: self.loginAction),
                    Cell(factory: { Self.defaultCell($0, text: "Create an Account") }, action: self.registerAction),
                ]
            ),
        ]
    }

    private func authorizedSections() -> [Section] {
        return [
            Section(
                header: nil,
                cells: [
                    Cell(factory: { Self.defaultCell($0, text: State.manager.userEmail) }),
                ]
            ),
            Section(
                header: "Groceries",
                cells: [
                    Cell(
                        factory: { (cell) in
                            var content = SwitchContentConfiguration()
                            content.text = "Sort Checked Items"
                            content.isOn = PersistenceManager.shared.sortCheckedGroceries
                            content.onChange = { (toggled) in
                                PersistenceManager.shared.sortCheckedGroceries = toggled
                                if toggled {
                                    State.manager.groceryList.sortCheckedGroceries()
                                    State.manager.storeGroceryList()
                                }
                            }
                            return content
                        },
                        reuseId: Self.switchReuseID
                    ),
                ]
            ),
            Section(
                header: "Account",
                cells: [
                    Cell(factory: { Self.destructiveCell($0, text: "Sign Out", image: SFSymbols.logout) }, action: self.logoutAction),
                    Cell(factory: { Self.destructiveCell($0, text: "Delete Account", image: SFSymbols.trash) }, action: self.deleteAccountAction),
                ]
            ),
        ]
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

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.reuseID)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.switchReuseID)

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
        let message = "Are you sure you wish to sign out?"
        let warning = WarningAlert(title: "", message: message) { [weak self] () in
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

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sections[section].cells.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sections[section].header
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellConfig = self.sections[indexPath.section].cells[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellConfig.reuseId)!
        cell.contentConfiguration = cellConfig.factory(cell)
        cell.selectionStyle = cellConfig.action == nil ? .none : .default
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.sections[indexPath.section].cells[indexPath.row].action?()
    }
}
