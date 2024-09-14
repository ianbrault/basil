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

    protocol Delegate: AnyObject {
        func didSaveRecipe(style: RecipeFormVC.Style, recipe: Recipe)
    }

    enum Style {
        case new
        case edit
    }

    enum Section: Int, CaseIterable {
        case title = 0
        case ingredients = 1
        case instructions = 2
    }

    struct Cell: Hashable {
        enum Style: Hashable {
            case textField
            case button
        }

        let id: UUID
        let style: Style
        var text: String

        init(_ style: Style, text: String = "") {
            self.id = UUID()
            self.style = style
            self.text = text
        }
    }

    class DataSource: UITableViewDiffableDataSource<Section, Cell> {

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

    private var cancelButton: UIBarButtonItem!
    private var editButton: UIBarButtonItem!
    private var doneButton: UIBarButtonItem!
    private var saveButton: UIBarButtonItem!

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var cells: [[Cell]] = [
        [Cell(.textField)],
        [Cell(.textField), Cell(.button)],
        [Cell(.textField), Cell(.button)],
    ]

    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Cell>

    private lazy var dataSource = DataSource(tableView: self.tableView) { (tableView, indexPath, info) -> RecipeFormCell? in
        var reuseID: String
        switch self.cells[indexPath.section][indexPath.row].style {
        case .textField:
            reuseID = RecipeFormCell.textFieldReuseID
        case .button:
            reuseID = RecipeFormCell.buttonReuseID
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseID, for: indexPath) as? RecipeFormCell
        cell?.delegate = self
        cell?.set(info, for: indexPath)
        return cell
    }

    private var style: Style
    var uuid: UUID?
    var folderId: UUID?
    weak var delegate: Delegate?

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
        self.dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
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

        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.navigationBar.tintColor = StyleGuide.colors.primary
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }

    private func configureViewController() {
        self.view.backgroundColor = .systemGroupedBackground

        // create the bar button items
        self.cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.dismissVC))
        self.editButton = UIBarButtonItem(title: nil, image: SFSymbols.reorder, target: self, action: #selector(self.enableEditMode))
        self.doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.disableEditMode))
        self.saveButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(self.saveRecipe))

        self.navigationItem.leftBarButtonItem = self.cancelButton
        self.navigationItem.rightBarButtonItems = [self.saveButton, self.editButton]
    }

    private func configureTableView() {
        self.view.addSubview(self.tableView)

        self.tableView.delegate = self
        self.tableView.contentInset.bottom = 16
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.removeExcessCells()

        self.tableView.register(RecipeFormCell.self, forCellReuseIdentifier: RecipeFormCell.textFieldReuseID)
        self.tableView.register(RecipeFormCell.self, forCellReuseIdentifier: RecipeFormCell.buttonReuseID)

        self.tableView.pinToSides(of: self.view)
        self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.tableView.bottomAnchor.constraint(equalTo: self.view.keyboardLayoutGuide.topAnchor).isActive = true
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

    @objc func dismissVC() {
        self.dismiss(animated: true)
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
            if cell.style == .button {
                continue
            }
            let ingredient = IngredientParser.shared.parse(string: cell.text)
            ingredients.append(ingredient)
        }
        // gather the instructions
        var instructions: [String] = []
        for cell in self.cells[Section.instructions.rawValue] {
            if cell.style == .button {
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
        self.dismissVC()
    }
}

extension RecipeFormVC: UITableViewDelegate {

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // filter for button cells
        if indexPath.row < self.cells[indexPath.section].count - 1 {
            return
        }
        // add a new input cell when pressed
        self.cells[indexPath.section].insert(Cell(.textField), at: self.cells[indexPath.section].count - 1)

        // apply UI updates
        // first deselect the button row
        tableView.deselectRow(at: indexPath, animated: true)
        // then apply the snapshot to append the new input row
        self.applySnapshot()
        // and finally focus the new input row
        DispatchQueue.main.async {
            tableView.cellForRow(at: indexPath)?.becomeFirstResponder()
        }
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        // do not allow the title to be deleted
        guard let section = Section(rawValue: indexPath.section), section != .title else { return nil }

        let contextItem = UIContextualAction(style: .destructive, title: "Delete") {  (action, view, actionPerformed) in
            self.cells[indexPath.section].remove(at: indexPath.row)
            self.applySnapshot()
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

extension RecipeFormVC: RecipeFormCell.Delegate {

    func textFieldDidChange(text: String, sender: UIResponder) {
        if let cell = sender.next(ofType: RecipeFormCell.self) {
            if let indexPath = tableView.indexPath(for: cell) {
                self.cells[indexPath.section][indexPath.row].text = text
            }
        }
    }
}
