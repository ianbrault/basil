//
//  RecipeFormVC.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/26/23.
//

import UIKit

//
// Displays a form to create/edit a recipe
//
class RecipeFormVC: UIViewController {

    private typealias Cell = RecipeFormCell.Info
    private typealias Section = RecipeFormCell.Section
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Cell>

    protocol Delegate: AnyObject {
        func didSaveRecipe(style: RecipeFormVC.Style, recipe: Recipe)
    }

    enum Style {
        case new
        case edit
    }

    private class DataSource: UITableViewDiffableDataSource<Section, Cell> {

        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            guard let tableSection = Section(rawValue: section) else { return nil }
            switch tableSection {
            case .title:
                return "Title"
            case .ingredients:
                return "Ingredients"
            case .instructions:
                return "Instructions"
            }
        }

        override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
            guard tableView.isEditing, let section = Section(rawValue: indexPath.section) else { return false }
            return indexPath.row < self.snapshot().numberOfItems(inSection: section) - 1
        }

        override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
            // move must be within the same section
            guard sourceIndexPath.section == destinationIndexPath.section else { return }
            super.tableView(tableView, moveRowAt: sourceIndexPath, to: destinationIndexPath)
            var snapshot = self.snapshot()

            if let sourceId = self.itemIdentifier(for: sourceIndexPath), let destinationId = self.itemIdentifier(for: destinationIndexPath) {
                // destination and source must be distinct
                guard sourceId != destinationId else { return }
                if sourceIndexPath.row > destinationIndexPath.row {
                    snapshot.moveItem(sourceId, beforeItem: destinationId)
                } else {
                    snapshot.moveItem(sourceId, afterItem: destinationId)
                }
            }

            self.apply(snapshot, animatingDifferences: false)
        }
    }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var style: Style
    private var cells: [[Cell]] = [
        [Cell(.textField)],
        [Cell(.textField), Cell(.button)],
        [Cell(.textField), Cell(.button)],
    ]

    private lazy var dataSource = DataSource(tableView: self.tableView) { (tableView, indexPath, info) -> RecipeFormCell? in
        var reuseID: String
        switch self.cells[indexPath.section][indexPath.row].style {
        case .textField:
            reuseID = RecipeFormCell.textFieldReuseID
        case .button:
            reuseID = RecipeFormCell.buttonReuseID
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseID, for: indexPath) as! RecipeFormCell
        cell.onChange = { [weak self] (text) in
            guard let index = self?.tableView.indexPath(for: cell) else { return }
            self?.cells[index.section][index.row].text = text
            // allow text fields to expand or shrink lines
            self?.tableView.beginUpdates()
            self?.tableView.endUpdates()
        }
        cell.onEndEditing = { [weak self] (_) in
            self?.applySnapshot(animatingDifferences: false)
        }
        cell.onButtonTap = self.onButtonTap
        cell.set(info, for: indexPath)
        return cell
    }

    var uuid: UUID?
    var folderId: UUID?
    weak var delegate: Delegate?

    private var cancelButton: UIBarButtonItem!
    private var editButton: UIBarButtonItem!
    private var doneButton: UIBarButtonItem!
    private var saveButton: UIBarButtonItem!

    init(style: Style) {
        self.style = style
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applySnapshot(animatingDifferences: Bool = true) {
        var snapshot = Snapshot()
        snapshot.appendSections(Section.allCases)
        for section in Section.allCases {
            snapshot.appendItems(self.cells[section.rawValue], toSection: section)
        }
        DispatchQueue.main.async {
            self.dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureNavigationController()
        self.configureViewController()
        self.configureTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        self.applySnapshot(animatingDifferences: false)
    }

    private func configureNavigationController() {
        switch self.style {
        case .new:
            self.title = "New Recipe"
        case .edit:
            self.title = "Edit Recipe"
        }
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }

    private func configureViewController() {
        self.view.backgroundColor = StyleGuide.colors.groupedBackground

        // create the bar button items
        self.cancelButton = self.createBarButton(systemItem: .cancel, action: #selector(self.dismissSelf))
        self.editButton = self.createBarButton(image: SFSymbols.reorder, action: #selector(self.enableEditMode))
        self.doneButton = self.createBarButton(systemItem: .done, action: #selector(self.disableEditMode))
        self.saveButton = self.createBarButton(title: "Save", style: .done, action: #selector(self.saveRecipe))

        self.navigationItem.leftBarButtonItem = self.cancelButton
        self.navigationItem.rightBarButtonItems = [self.saveButton, self.editButton]
    }

    private func configureTableView() {
        self.tableView.delegate = self
        self.tableView.contentInset.bottom = 16
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.removeExcessCells()

        self.tableView.register(RecipeFormCell.self, forCellReuseIdentifier: RecipeFormCell.textFieldReuseID)
        self.tableView.register(RecipeFormCell.self, forCellReuseIdentifier: RecipeFormCell.buttonReuseID)

        self.view.addPinnedSubview(self.tableView, keyboardBottom: true)

        // tap to dismiss keyboard
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        self.tableView.addGestureRecognizer(gesture)
    }

    func set(recipe: Recipe) {
        self.uuid = recipe.uuid
        self.folderId = recipe.folderId

        // add the title cell
        self.cells[Section.title.rawValue].removeAll()
        self.cells[Section.title.rawValue].append(Cell(.textField, text: recipe.title))

        // add the ingredients cells
        self.cells[Section.ingredients.rawValue].removeAll()
        for ingredient in recipe.ingredients {
            self.cells[Section.ingredients.rawValue].append(Cell(.textField, text: ingredient.toString()))
        }
        self.cells[Section.ingredients.rawValue].append(Cell(.button))

        // add the instructions cells
        self.cells[Section.instructions.rawValue].removeAll()
        for instruction in recipe.instructions {
            self.cells[Section.instructions.rawValue].append(Cell(.textField, text: instruction))
        }
        self.cells[Section.instructions.rawValue].append(Cell(.button))
    }

    private func onButtonTap(_ sender: UITableViewCell, _ location: RecipeFormCell.TapLocation) {
        guard let indexPath = self.tableView.indexPath(for: sender) else { return }
        // add a new input cell when pressed
        let text = location == .section ? Recipe.sectionHeader : ""
        self.cells[indexPath.section].insert(Cell(.textField, text: text), at: self.cells[indexPath.section].count - 1)
        self.applySnapshot()
        // then focus the new input row
        self.tableView.cellForRow(at: indexPath)?.becomeFirstResponder()
    }

    @objc func dismissKeyboard(_ action: UIAction) {
        self.tableView.endEditing(true)
    }

    @objc func enableEditMode(_ action: UIAction? = nil) {
        self.tableView.setEditing(true, animated: true)
        self.navigationItem.rightBarButtonItems = [self.doneButton]
    }

    @objc func disableEditMode(_ action: UIAction? = nil) {
        self.tableView.setEditing(false, animated: true)
        self.navigationItem.rightBarButtonItems = [self.saveButton, self.editButton]
    }

    @objc func saveRecipe() {
        // verify that the title is filled out
        let title = self.cells[Section.title.rawValue][0].text
        if title.isEmpty {
            self.presentErrorAlert(.missingTitle)
            return
        }

        // gather the ingredients
        var ingredients: [Ingredient] = []
        for cell in self.cells[Section.ingredients.rawValue] {
            if cell.style == .button || cell.text.isEmpty {
                continue
            }
            let ingredient = IngredientParser.shared.parse(string: cell.text)
            ingredients.append(ingredient)
        }
        // gather the instructions
        var instructions: [String] = []
        for cell in self.cells[Section.instructions.rawValue] {
            if cell.style == .button || cell.text.isEmpty {
                continue
            }
            instructions.append(cell.text)
        }

        let recipe = Recipe(
            uuid: self.uuid ?? UUID(),
            folderId: self.folderId ?? UUID(),
            title: title,
            ingredients: ingredients,
            instructions: instructions)
        self.delegate?.didSaveRecipe(style: self.style, recipe: recipe)
        self.dismissSelf()
    }
}

extension RecipeFormVC: UITableViewDelegate {

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        // do not allow the title to be deleted
        guard let section = Section(rawValue: indexPath.section), section != .title else { return nil }

        let contextItem = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, actionPerformed) in
            self?.cells[indexPath.section].remove(at: indexPath.row)
            self?.applySnapshot()
            actionPerformed(true)
        }
        // do not allow buttons to be deleted
        if self.cells[indexPath.section][indexPath.row].style != .button {
            return UISwipeActionsConfiguration(actions: [contextItem])
        } else {
            return nil
        }
    }

    func tableView(
        _ tableView: UITableView,
        targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
        toProposedIndexPath proposedDestinationIndexPath: IndexPath
    ) -> IndexPath {
        // prevent moving from across sections
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            return sourceIndexPath
        }
        // prevent moving past the button in the section
        if proposedDestinationIndexPath.row >= self.cells[sourceIndexPath.section].count - 1 {
            return sourceIndexPath
        }
        return proposedDestinationIndexPath
    }
}
