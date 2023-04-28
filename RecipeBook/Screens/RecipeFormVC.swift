//
//  NewRecipeVCBeta.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/26/23.
//

import UIKit

protocol RecipeFormVCDelegate: AnyObject {
    func didSaveRecipe(recipe: Recipe)
}

class RecipeFormVC: UIViewController {

    enum Style {
        case new
        case edit

        var title: String {
            switch self {
            case .new:
                return "New Recipe"
            case .edit:
                return "Edit Recipe"
            }
        }
    }

    enum Section: Int {
        case title = 0
        case ingredients = 1
        case instructions = 2

        var header: String? {
            switch self {
            case .title:
                return nil
            case .ingredients:
                return "Ingredients"
            case .instructions:
                return "Instructions"
            }
        }

        var textFieldPlaceholder: String {
            switch self {
            case .title:
                return "Title"
            case .ingredients:
                return "ex: 1 tbsp. olive oil"
            case .instructions:
                return "ex: Preheat the oven to 350°F"
            }
        }

        var actionButtonText: String? {
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

    let tableView = UITableView()
    var tableCells: [[RecipeFormCell.Content]] = [
        [.createInput()],
        [.createInput(), .createButton()],
        [.createInput(), .createButton()],
    ]
    let tableTopPadding: CGFloat = 20
    let tableBottomPadding: CGFloat = 100

    var style: Style!
    var uuid: UUID?
    weak var delegate: RecipeFormVCDelegate?

    init(style: Style) {
        super.init(nibName: nil, bundle: nil)
        self.style = style
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureNavigationController()
        self.configureViewController()
        self.configureTableView()
        self.createDismissKeyboardTapGesture()
        self.createKeyboardNotificationObservers()
    }

    func configureNavigationController() {
        self.title = self.style.title
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }

    func configureViewController() {
        self.view.backgroundColor = .systemGroupedBackground

        // dismiss the view when the cancel button is tapped
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissVC))
        self.navigationItem.leftBarButtonItem = cancelButton

        // save the recipe when the save button is tapped
        let saveButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveRecipe))
        self.navigationItem.rightBarButtonItem = saveButton
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
        // dismiss the keyboard when the view is tapped
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        self.view.addGestureRecognizer(tap)
    }

    func createKeyboardNotificationObservers() {
        self.addNotificationObserver(
            name: UIResponder.keyboardWillShowNotification,
            selector: #selector(onKeyboardAppear))
        self.addNotificationObserver(
            name: UIResponder.keyboardWillHideNotification,
            selector: #selector(onKeyboardDisappear))
    }

    func set(recipe: Recipe) {
        self.uuid = recipe.uuid

        let titleSection = Section.title.rawValue
        let ingredientsSection = Section.ingredients.rawValue
        let instructionsSection = Section.instructions.rawValue

        // add the title cell
        let titleCell = RecipeFormCell.Content.createInput(text: recipe.title)
        self.tableCells[titleSection].removeAll()
        self.tableCells[titleSection].append(titleCell)

        // add the ingredients cells
        self.tableCells[ingredientsSection].removeAll()
        for ingredient in recipe.ingredients {
            let ingredientCell = RecipeFormCell.Content.createInput(text: ingredient.item)
            self.tableCells[ingredientsSection].append(ingredientCell)
        }
        self.tableCells[ingredientsSection].append(RecipeFormCell.Content.createButton())

        // add the instructions cells
        self.tableCells[instructionsSection].removeAll()
        for instruction in recipe.instructions {
            let instructionCell = RecipeFormCell.Content.createInput(text: instruction.step)
            self.tableCells[instructionsSection].append(instructionCell)
        }
        self.tableCells[instructionsSection].append(RecipeFormCell.Content.createButton())
    }

    func appendInputCell(section: Section) {
        let input = RecipeFormCell.Content.createInput()
        let index = self.tableCells[section.rawValue].count - 1

        self.tableCells[section.rawValue].insert(input, at: index)
        let indexPath = IndexPath(row: index, section: section.rawValue)
        self.tableView.insertRows(at: [indexPath], with: .automatic)

        // scroll to the new input
        self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        // and focus the new input
        let cell = self.tableView.cellForRow(at: indexPath) as! RecipeFormCell
        cell.textField?.becomeFirstResponder()
    }

    func indexPathFromUuid(uuid: UUID) -> IndexPath? {
        for (sectionIndex, sectionCells) in self.tableCells.enumerated() {
            for (rowIndex, cell) in sectionCells.enumerated() {
                if cell.uuid == uuid {
                    return IndexPath(row: rowIndex, section: sectionIndex)
                }
            }
        }
        return nil
    }

    @objc func onKeyboardAppear(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardHeight = keyboardFrame.cgRectValue.height
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.1) {
                    self.tableView.contentInset.bottom = keyboardHeight + self.tableBottomPadding
                }
            }
        }
    }

    @objc func onKeyboardDisappear() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.1) {
                self.tableView.contentInset.bottom = self.tableBottomPadding
            }
        }
    }

    @objc func dismissVC() {
        self.dismiss(animated: true)
    }

    @objc func saveRecipe() {
        // check that the title is filled out
        let title = self.tableCells[Section.title.rawValue][0].text!
        if title.isEmpty {
            self.presentErrorAlert(.missingTitle)
            return
        }

        // gather the ingredients
        var ingredients: [Ingredient] = []
        for cell in self.tableCells[Section.ingredients.rawValue] {
            switch cell.type {
            case .input:
                ingredients.append(Ingredient(item: cell.text!))
            case .actionButton:
                continue
            }
        }
        // gather the instructions
        var instructions: [Instruction] = []
        for cell in self.tableCells[Section.instructions.rawValue] {
            switch cell.type {
            case .input:
                instructions.append(Instruction(step: cell.text!))
            case .actionButton:
                continue
            }
        }

        let recipe = Recipe(
            uuid: self.uuid ?? UUID(),
            title: title,
            ingredients: ingredients,
            instructions: instructions)
        self.delegate?.didSaveRecipe(recipe: recipe)
        self.dismissVC()
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
        return tableSection.header
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = Section(rawValue: indexPath.section)!
        let content = self.tableCells[indexPath.section][indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: RecipeFormCell.reuseID) as! RecipeFormCell
        cell.delegate = self
        cell.set(section: section, content: content)
        return cell
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let contextItem = UIContextualAction(style: .destructive, title: "Delete") {  (action, view, actionPerformed) in
            self.tableCells[indexPath.section].remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            actionPerformed(true)
        }

        // do not allow the title to be deleted
        if indexPath.section == Section.title.rawValue {
            return nil
        }

        switch self.tableCells[indexPath.section][indexPath.row].type {
        // do not allow buttons to be deleted
        case .actionButton:
            return nil
        case .input:
            return UISwipeActionsConfiguration(actions: [contextItem])
        }
    }
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
            // add a slight delay to allow the keyboard to displace the screen
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            }
        } else {
            self.presentErrorAlert(.missingInput(uuid))
        }
    }

    func textFieldDidChange(_ uuid: UUID, text: String?) {
        guard let text else { return }
        if let indexPath = self.indexPathFromUuid(uuid: uuid) {
            let cell = self.tableCells[indexPath.section][indexPath.row]
            self.tableCells[indexPath.section][indexPath.row] = .createInput(uuid: cell.uuid, text: text)
        } else {
            self.presentErrorAlert(.missingInput(uuid))
        }
    }
}
