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
class SettingsVC: UIViewController {
    static let reuseID = "SettingsCell"

    // future features:
    // change email
    // change password
    enum Section: Int, CaseIterable {
        case account
        case logout
    }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureNavigationController()
        self.configureViewController()
        self.configureTableView()
    }

    private func configureNavigationController() {
        self.title = "Settings"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.navigationBar.tintColor = Style.colors.primary
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
        self.tableView.separatorInsetReference = .fromAutomaticInsets
        self.tableView.removeExcessCells()

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: SettingsVC.reuseID)
        self.tableView.setContentOffset(CGPoint(x: 0, y: -100), animated: true)
    }

    @objc func dismissVC() {
        self.dismiss(animated: true)
    }
}

extension SettingsVC: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Style.tableCellHeight
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tableSection = Section(rawValue: section) else { return 0 }
        switch tableSection {
        case .account:
            return 1
        case .logout:
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsVC.reuseID)!
        let section = Section(rawValue: indexPath.section)!

        var content = cell.defaultContentConfiguration()
        switch section {
        case .account:
            content.text = State.manager.userEmail
            content.textProperties.color = Style.colors.primaryText
            content.image = nil
        case .logout:
            content.text = "Sign out"
            content.textProperties.color = Style.colors.error
            content.image = SFSymbols.logout
            content.imageProperties.tintColor = Style.colors.error
        }

        cell.contentConfiguration = content
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else { return }

        switch section {
        case .logout:
            // clear all stored user state and return to the onboaring window
            State.manager.clearUserInfo()
            if let delegate = self.view.window?.windowScene?.delegate as? SceneDelegate {
                delegate.sceneDidRemoveUser()
            }
        default:
            return
        }
    }
}
