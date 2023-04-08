//
//  RecipeVC.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/24/23.
//

import UIKit

class RecipeVC: UIViewController {
    static let padding: CGFloat = 20
    static let headingTextSize: CGFloat = 18
    static let bodyTextSize: CGFloat = 16

    let scrollView = UIScrollView()
    let stackView = UIStackView()
    let ingredientsTitleLabel = RBTitleLabel(fontSize: RecipeVC.headingTextSize, weight: .semibold)
    let ingredientsListView = RBBulletedListView(fontSize: RecipeVC.bodyTextSize)
    let instructionsTitleLabel = RBTitleLabel(fontSize: RecipeVC.headingTextSize, weight: .semibold)
    let instructionsListView = RBNumberedListView(fontSize: RecipeVC.bodyTextSize)

    var recipe: Recipe!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureNavigationBar()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureViewController()
        self.configureScrollView()
        self.configureIngredientsTitleLabel()
        self.configureIngredientsListView()
        self.configureInstructionsTitleLabel()
        self.configureInstructionsListView()
    }

    private func configureNavigationBar() {
        self.title = recipe.title
        self.navigationController?.navigationBar.prefersLargeTitles = true

        let appearance = UINavigationBarAppearance()
        appearance.largeTitleTextAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 24, weight: .bold),
        ]
        self.navigationController?.navigationBar.standardAppearance = appearance
    }

    private func configureViewController() {
        self.view.backgroundColor = .systemBackground
    }

    private func configureScrollView() {
        self.view.addSubview(self.scrollView)
        self.scrollView.pinToEdges(of: self.view)

        self.scrollView.addSubview(self.stackView)
        self.stackView.axis = .vertical
        self.stackView.spacing = 20
        self.stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            self.stackView.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: RecipeVC.padding / 2),
            self.stackView.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor, constant: RecipeVC.padding),
            self.stackView.trailingAnchor.constraint(equalTo: self.scrollView.trailingAnchor, constant: -RecipeVC.padding),
            self.stackView.widthAnchor.constraint(equalTo: self.scrollView.widthAnchor, constant: -RecipeVC.padding * 2),
        ])
    }

    private func configureIngredientsTitleLabel() {
        self.stackView.addArrangedSubview(self.ingredientsTitleLabel)
        self.stackView.setCustomSpacing(4, after: self.ingredientsTitleLabel)
        self.ingredientsTitleLabel.text = "Ingredients"
    }

    private func configureIngredientsListView() {
        self.stackView.addArrangedSubview(self.ingredientsListView)

        var ingredients: [String] = []
        for ingredient in self.recipe.ingredients {
            ingredients.append(ingredient.item)
        }
        self.ingredientsListView.setItems(items: ingredients)
        self.ingredientsListView.sizeToFit()
        self.ingredientsListView.isScrollEnabled = false
    }

    private func configureInstructionsTitleLabel() {
        self.stackView.addArrangedSubview(self.instructionsTitleLabel)
        self.stackView.setCustomSpacing(16, after: self.instructionsTitleLabel)
        self.instructionsTitleLabel.text = "Instructions"
    }

    private func configureInstructionsListView() {
        self.stackView.addArrangedSubview(self.instructionsListView)

        var instructions: [String] = []
        for instruction in self.recipe.instructions {
            instructions.append(instruction.step)
        }
        self.instructionsListView.setItems(items: instructions)
        NSLayoutConstraint.activate([
            self.instructionsListView.leadingAnchor.constraint(equalTo: self.stackView.leadingAnchor),
            self.instructionsListView.trailingAnchor.constraint(equalTo: self.stackView.trailingAnchor),
            self.instructionsListView.widthAnchor.constraint(equalTo: self.stackView.widthAnchor),
        ])
    }
}
