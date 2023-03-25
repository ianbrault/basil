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
        configureViewController()
        configureScrollView()
        configureRecipeTitleLabel()
    }

    func configureViewController() {
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    func configureScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.pinToEdges(of: view)
        contentView.pinToEdges(of: scrollView)

        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])
    }

    func configureRecipeTitleLabel() {
        contentView.addSubview(recipeTitleLabel)
        recipeTitleLabel.text = recipe.title

        let padding: CGFloat = 24
        NSLayoutConstraint.activate([
            recipeTitleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            recipeTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            recipeTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            recipeTitleLabel.heightAnchor.constraint(equalToConstant: 36),
        ])
    }
}
