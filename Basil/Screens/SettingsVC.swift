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
class SettingsVC: UIViewController {
    static let reuseID = "SettingsCell"

    protocol Delegate: AnyObject {
        func didChangeUser()
    }

    struct Section {
        let cell: (inout UIListContentConfiguration) -> Void
        let action: (() -> Void)?
    }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var sections: [[Section]] = []
    weak var delegate: Delegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureNavigationController()
        self.configureViewController()
        self.configureTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.registerSections()
    }

    private func registerSections() {
        if State.manager.userId.isEmpty {
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
        } else {
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

    private func configureViewController() {
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.dismissVC))
        self.navigationItem.rightBarButtonItem = doneButton
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

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: SettingsVC.reuseID)
        self.tableView.setContentOffset(CGPoint(x: 0, y: -100), animated: true)
    }

    private func userAdded(_ error: RBError?) {
        DispatchQueue.main.async {
            if let error {
                self.presentErrorAlert(error)
            } else {
                self.registerSections()
                self.tableView.reloadData()
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    private func loginAction() {
        // TODO: add an option to import the recipes/folders into the account after logging in
        if !State.manager.recipes.isEmpty || State.manager.folders.count > 1 {
            let message = "Logging in to an existing account will remove your previously-saved recipes. " +
                          "Are you sure you want to continue?"
            let warning = WarningAlert(message) {
                let vc = OnboardingFormVC(.login, onCompletion: self.userAdded)
                self.navigationController?.pushViewController(vc, animated: true)
            }
            self.present(warning, animated: true)
        } else {
            let vc = OnboardingFormVC(.login, onCompletion: self.userAdded)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    private func registerAction() {
        let vc = OnboardingFormVC(.register, onCompletion: self.userAdded)
        self.navigationController?.pushViewController(vc, animated: true)
    }

    private func logoutAction() {
        let message = "Logging out will remove any saved recipes until you log back in to your account. " +
                      "Are you sure you want to continue?"
        let warning = WarningAlert(message) {
            // clear all stored user state and return to the previous screen
            // FIXME: this does not refresh the recipe list view
            State.manager.clearUserInfo()
            self.dismissVC()
            self.delegate?.didChangeUser()
        }
        self.present(warning, animated: true)
    }

    @objc func dismissVC() {
        self.dismiss(animated: true)
    }
}

extension SettingsVC: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return StyleGuide.tableCellHeight
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sections[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsVC.reuseID)!
        var content = cell.defaultContentConfiguration()
        self.sections[indexPath.section][indexPath.row].cell(&content)
        cell.contentConfiguration = content
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.sections[indexPath.section][indexPath.row].action?()
    }
}
