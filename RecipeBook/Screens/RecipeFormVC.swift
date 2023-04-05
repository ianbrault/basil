//
//  NewRecipeVCBeta.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/26/23.
//

import UIKit

class RecipeFormVC: UIViewController {

    enum Section: Int {
        case title = 0
        case ingredients = 1
        case instructions = 2
    }

    let tableView = UITableView()
    var tableCells: [[RecipeFormCell.Content]] = [
        [.createInput()],
        [.createInput(), .createButton()],
        [.createInput(), .createButton()],
    ]
    let tableTopPadding: CGFloat = 20
    let tableBottomPadding: CGFloat = 100

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureNavigationController()
        self.configureViewController()
        self.configureTableView()
        self.createDismissKeyboardTapGesture()
        self.createKeyboardNotificationObservers()
    }

    func configureNavigationController() {
        self.title = "New Recipe"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }

    func configureViewController() {
        self.view.backgroundColor = .systemGroupedBackground
    }

    func configureTableView() {
        self.view.addSubview(self.tableView)

        self.tableView.frame = self.view.bounds
        self.tableView.contentInset.bottom = self.tableBottomPadding
        self.tableView.removeExcessCells()

        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.tableView.register(RecipeFormCell.self, forCellReuseIdentifier: RecipeFormCell.reuseID)
    }

    func createDismissKeyboardTapGesture() {
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        self.view.addGestureRecognizer(tap)
    }

    func createKeyboardNotificationObservers() {
        self.addNotificationObserver(name: UIResponder.keyboardWillShowNotification, selector: #selector(onKeyboardAppear))
        self.addNotificationObserver(name: UIResponder.keyboardWillHideNotification, selector: #selector(onKeyboardDisappear))
    }

    @objc func onKeyboardAppear() {
        print("onKeyboardAppear")
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.1) {
                self.tableView.contentInset.bottom = 380
            }
        }
    }

    @objc func onKeyboardDisappear() {
        print("onKeyboardDisappear")
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2) {
                self.tableView.contentInset.bottom = self.tableBottomPadding
            }
        }
    }

    func appendInputCell(section: Section) {
        // TODO: focus (and scroll to) the new input
        let input = RecipeFormCell.Content.createInput()
        let index = self.tableCells[section.rawValue].count - 1

        self.tableCells[section.rawValue].insert(input, at: index)
        self.tableView.reloadData()
    }

    func indexPathFromUuid(uuid: UUID) -> IndexPath? {
        for (sectionIndex, sectionCells) in self.tableCells.enumerated() {
            for (rowIndex, cell) in sectionCells.enumerated() {
                if cell.uuid() == uuid {
                    return IndexPath(row: rowIndex, section: sectionIndex)
                }
            }
        }
        return nil
    }
}

extension RecipeFormVC: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.tableCells.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableCells[section].count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let tableSection = Section(rawValue: section)!
        return tableSection.header()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = Section(rawValue: indexPath.section)!
        let content = self.tableCells[indexPath.section][indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: RecipeFormCell.reuseID) as! RecipeFormCell
        cell.delegate = self
        cell.set(section: section, content: content)
        return cell
    }

    /*
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        // TODO: unimplemented
    }
    */
}

extension RecipeFormVC: RecipeFormCellDelegate {

    func ingredientsButtonPressed() {
        self.appendInputCell(section: .ingredients)
    }

    func instructionsButtonPressed() {
        self.appendInputCell(section: .instructions)
    }

    func textFieldDidBeginEditing(_ uuid: UUID) {
        if let indexPath = self.indexPathFromUuid(uuid: uuid) {
            DispatchQueue.main.async {
                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            }
        } else {
            self.presentErrorAlert(title: "Something went wrong", message: "Missing input \(uuid)")
        }
    }
}

extension RecipeFormVC.Section {

    func header() -> String? {
        switch self {
        case .title:
            return nil
        case .ingredients:
            return "Ingredients"
        case .instructions:
            return "Instructions"
        }
    }

    func textFieldPlaceholder() -> String {
        switch self {
        case .title:
            return "Title"
        case .ingredients:
            return "ex: 1 tbsp. olive oil"
        case .instructions:
            return "ex: Preheat the oven to 350°F"
        }
    }

    func actionButtonText() -> String? {
        switch self {
        case .title:
            return nil
        case .ingredients:
            return "Add another ingredient"
        case .instructions:
            return "Add another step"
        }
    }
}
