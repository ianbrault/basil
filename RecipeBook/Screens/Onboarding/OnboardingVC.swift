//
//  OnboardingVC.swift
//  RecipeBook
//
//  Created by Ian Brault on 11/12/23.
//

import UIKit

class OnboardingVC: UIPageViewController {

    var pages: [UIViewController] = []
    let pageControl = UIPageControl()
    let initialPage = 0

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

    private func configure() {
        self.dataSource = self
        self.delegate = self

        self.pages.append(WelcomeVC())
        self.pages.append(RegisterVC())
        self.pages.append(LoginVC())

        self.setViewControllers([self.pages[self.initialPage]], direction: .forward, animated: true, completion: nil)
    }

    private func configurePageControl() {
        self.view.addSubview(self.pageControl)
        self.pageControl.translatesAutoresizingMaskIntoConstraints = false

        self.pageControl.currentPageIndicatorTintColor = .black
        self.pageControl.pageIndicatorTintColor = .systemGray2
        self.pageControl.numberOfPages = self.pages.count
        self.pageControl.currentPage = self.initialPage

        self.pageControl.pinToEdges(of: self.view)
    }
}

extension OnboardingVC: UIPageViewControllerDataSource {

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let index = self.pages.firstIndex(of: viewController) else { return nil }

        if index == 0 {
            return self.pages.last
        } else {
            return self.pages[index - 1]
        }
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let index = self.pages.firstIndex(of: viewController) else { return nil }

        if index < self.pages.count - 1 {
            return self.pages[index + 1]
        } else {
            return self.pages.first
        }
    }
}

extension OnboardingVC: UIPageViewControllerDelegate {

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard let viewControllers = pageViewController.viewControllers else { return }
        guard let currentIndex = pages.firstIndex(of: viewControllers[0]) else { return }

        pageControl.currentPage = currentIndex
    }
}
