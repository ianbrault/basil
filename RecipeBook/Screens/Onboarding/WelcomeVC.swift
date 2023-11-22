//
//  WelcomeVC.swift
//  RecipeBook
//
//  Created by Ian Brault on 11/16/23.
//

import UIKit

class WelcomeVC: UIViewController {

    let logoImageView = UIImageView()
    let titleLabel = RBTitleLabel(fontSize: 28, textAlignment: .center)
    let messageLabel = RBBodyLabel(fontSize: 19, textAlignment: .center)
    let registerButton = RBButton(title: "Create a New Account", image: SFSymbols.register!)
    let loginButton = RBButton(title: "Login to your Account", image: SFSymbols.login!, style: .bordered)

    let spacing: CGFloat = 24
    let imageSize: CGFloat = 140
    let horizontalPadding: CGFloat = 48
    let topPadding: CGFloat = 100
    let bottomPadding: CGFloat = 64
    let buttonHeight: CGFloat = 58

    weak var delegate: OnboardingVCDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configure()
    }

    private func configure() {
        self.view.backgroundColor = .systemBackground

        self.configureLogoImageView()
        self.configureTitleLabel()
        self.configureMessageLabel()
        self.configureLoginButton()
        self.configureRegisterButton()
    }

    private func configureLogoImageView() {
        self.view.addSubview(self.logoImageView)

        let symbol = UIImage(
            systemName: "text.book.closed",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: self.imageSize, weight: .light))
        let image = symbol?.withTintColor(.darkGray, renderingMode: .alwaysOriginal)

        self.logoImageView.image = image
        self.logoImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            self.logoImageView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: self.topPadding),
            self.logoImageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.logoImageView.widthAnchor.constraint(equalToConstant: self.imageSize),
            self.logoImageView.heightAnchor.constraint(equalToConstant: self.imageSize),
        ])
    }

    private func configureTitleLabel() {
        self.view.addSubview(self.titleLabel)

        self.titleLabel.text = "Welcome 👋"
        self.titleLabel.numberOfLines = 0

        NSLayoutConstraint.activate([
            self.titleLabel.topAnchor.constraint(equalTo: self.logoImageView.bottomAnchor, constant: self.spacing / 1.5),
            self.titleLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.titleLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
        ])
    }

    private func configureMessageLabel() {
        self.view.addSubview(self.messageLabel)

        self.messageLabel.text = "Create an account to begin storing your recipes or log in to retrieve your collection"
        self.messageLabel.textColor = .secondaryLabel
        self.messageLabel.numberOfLines = 0

        NSLayoutConstraint.activate([
            self.messageLabel.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: self.spacing / 3),
            self.messageLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: self.horizontalPadding),
            self.messageLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -self.horizontalPadding),
        ])
    }

    private func configureLoginButton() {
        self.view.addSubview(self.loginButton)

        self.loginButton.addTarget(self, action: #selector(self.loginButtonPressed), for: .touchUpInside)

        NSLayoutConstraint.activate([
            self.loginButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -self.bottomPadding),
            self.loginButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: self.horizontalPadding),
            self.loginButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -self.horizontalPadding),
            self.loginButton.heightAnchor.constraint(equalToConstant: self.buttonHeight),
        ])
    }

    private func configureRegisterButton() {
        self.view.addSubview(self.registerButton)

        self.registerButton.addTarget(self, action: #selector(self.registerButtonPressed), for: .touchUpInside)

        NSLayoutConstraint.activate([
            self.registerButton.bottomAnchor.constraint(equalTo: self.loginButton.topAnchor, constant: -self.spacing),
            self.registerButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: self.horizontalPadding),
            self.registerButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -self.horizontalPadding),
            self.registerButton.heightAnchor.constraint(equalToConstant: self.buttonHeight),
        ])
    }

    @objc func registerButtonPressed() {
        self.delegate?.didChangePage(page: .register)
    }

    @objc func loginButtonPressed() {
        self.delegate?.didChangePage(page: .login)
    }
}
