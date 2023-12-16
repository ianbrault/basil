//
//  OnboardingVC.swift
//  RecipeBook
//
//  Created by Ian Brault on 11/12/23.
//

import UIKit

protocol OnboardingVCDelegate: AnyObject {
    func didChangePage(page: OnboardingVC.Page, direction: UIPageViewController.NavigationDirection)
}

class OnboardingVC: UIPageViewController {

    enum Page: Int {
        case welcome
        case register
        case login
    }

    var pages: [UIViewController] = []
    weak var sceneDelegate: RBWindowSceneDelegate?

    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configure()
    }

    private func setPage(_ page: Page, direction: UIPageViewController.NavigationDirection = .forward) {
        self.setViewControllers([self.pages[page.rawValue]], direction: direction, animated: true, completion: nil)
    }

    private func configure() {
        let welcomePage = WelcomeVC()
        welcomePage.delegate = self
        self.pages.append(welcomePage)

        let registerPage = RegisterVC()
        registerPage.delegate = self
        registerPage.sceneDelegate = self.sceneDelegate
        self.pages.append(registerPage)

        let loginPage = LoginVC()
        loginPage.delegate = self
        loginPage.sceneDelegate = self.sceneDelegate
        self.pages.append(loginPage)

        self.setPage(.welcome)
    }
}

extension OnboardingVC: OnboardingVCDelegate {

    func didChangePage(page: Page, direction: UIPageViewController.NavigationDirection) {
        self.setPage(page, direction: direction)
    }
}
