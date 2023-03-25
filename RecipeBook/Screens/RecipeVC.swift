//
//  RecipeVC.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/24/23.
//

import UIKit

class RecipeVC: UIViewController {

    let scrollView = UIScrollView()
    let contentView = UIView()
    let recipeTitleLabel = RBTitleLabel(fontSize: 24)

    var recipe: Recipe!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureViewController()
        self.configureScrollView()
        self.configureRecipeTitleLabel()
    }

    func configureViewController() {
        self.view.backgroundColor = .systemBackground
        self.navigationController?.navigationBar.prefersLargeTitles = false
    }

    func configureScrollView() {
        self.view.addSubview(self.scrollView)
        self.scrollView.addSubview(self.contentView)
        self.scrollView.pinToEdges(of: view)
        self.contentView.pinToEdges(of: self.scrollView)

        NSLayoutConstraint.activate([
            self.contentView.widthAnchor.constraint(equalTo: self.scrollView.widthAnchor),
        ])
    }

    func configureRecipeTitleLabel() {
        self.contentView.addSubview(self.recipeTitleLabel)
        self.recipeTitleLabel.text = self.recipe.title
        // dynamic sizing for recipe title
        var recipeTitleLines: CGFloat = 1
        if self.recipe.title.count > 24 {
            recipeTitleLines = 2
        }
        self.recipeTitleLabel.numberOfLines = Int(recipeTitleLines)
        let recipeTitleHeight = 36 * recipeTitleLines

        let padding: CGFloat = 24
        NSLayoutConstraint.activate([
            self.recipeTitleLabel.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.recipeTitleLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: padding),
            self.recipeTitleLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -padding),
            self.recipeTitleLabel.heightAnchor.constraint(equalToConstant: recipeTitleHeight),
        ])
    }
}
