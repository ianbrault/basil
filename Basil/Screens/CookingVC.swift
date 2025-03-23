//
//  CookingVC.swift
//  Basil
//
//  Created by Ian Brault on 3/13/25.
//

import UIKit

//
// Displays a set of views for cooking recipes
// Page view controller to allow swiping between pages
//
class CookingVC: UIPageViewController {

    protocol Delegate: AnyObject {
        func doneCooking()
    }

    private var recipes: [CookingItemVC] = []
    private var currentIndex: Int = 0

    weak var cookingDelegate: Delegate?

    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addRecipe(recipe: Recipe) {
        let viewController = CookingItemVC(recipe: recipe)
        self.currentIndex = self.recipes.count
        self.recipes.append(viewController)

        self.title = recipe.title
        self.setViewControllers([viewController], direction: .forward, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.dataSource = self
        self.delegate = self

        self.configureViewController()
        self.configureSheetPresentationController()

        UIPageControl.appearance().pageIndicatorTintColor = StyleGuide.colors.secondaryText
        UIPageControl.appearance().currentPageIndicatorTintColor = StyleGuide.colors.primary

        if let viewController = self.viewControllerAtIndex(self.currentIndex) {
            self.setViewControllers([viewController], direction: .forward, animated: false)
        }
    }

    private func configureViewController() {
        self.view.backgroundColor = StyleGuide.colors.background
        self.view.tintColor = StyleGuide.colors.primary

        // remove the swipe-to-dismiss gesture
        self.isModalInPresentation = true

        // create the bar button items
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.dismissVC))
        self.navigationItem.rightBarButtonItem = doneButton

        self.navigationItem.largeTitleDisplayMode = .never
    }

    private func configureSheetPresentationController() {
        if let controller = self.sheetPresentationController {
            controller.delegate = self
            controller.detents = [
                .large(),
                .custom { _ in
                    return 70
                }
            ]
            controller.selectedDetentIdentifier = .large
            controller.largestUndimmedDetentIdentifier = .large
        }
    }

    private func viewControllerAtIndex(_ index: Int) -> CookingItemVC? {
        guard index >= 0 && index < self.recipes.count else { return nil }
        return self.recipes[index]
    }

    @objc func dismissVC() {
        let alert = DoneCookingAlert { [weak self] in
            self?.cookingDelegate?.doneCooking()
            self?.dismiss(animated: true)
        }
        self.present(alert, animated: true)
    }
}

extension CookingVC: UISheetPresentationControllerDelegate {

    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(
        _ sheetPresentationController: UISheetPresentationController
    ) {
        if sheetPresentationController.selectedDetentIdentifier == .large {
            self.title = self.recipes[self.currentIndex].recipe.title
            // self.navigationController?.navigationBar.prefersLargeTitles = true
            // self.navigationItem.largeTitleDisplayMode = .always
            // scroll to the top of the view to force the large title to re-appear
            /*
            if let scrollView = self.view.subviews.first(where: { $0 as? UIScrollView != nil }) as? UIScrollView {
                scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: -1), animated: true)
            }
            */
        } else {
            self.title = "Cooking"
            // self.navigationController?.navigationBar.prefersLargeTitles = false
            // self.navigationItem.largeTitleDisplayMode = .never
        }
    }
}

extension CookingVC: UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return self.recipes.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return self.currentIndex
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController?
    {
        return self.viewControllerAtIndex(self.currentIndex - 1)
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController?
    {
        return self.viewControllerAtIndex(self.currentIndex + 1)
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard let controllers = pageViewController.viewControllers as? [CookingItemVC],
              let index = self.recipes.firstIndex(of: controllers[0]) else { return }

        self.currentIndex = index
        self.title = self.recipes[self.currentIndex].recipe.title
    }
}
