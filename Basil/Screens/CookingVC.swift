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
        var viewController: CookingItemVC
        var direction: UIPageViewController.NavigationDirection
        // check if the view already contains the recipe
        if let index = self.recipes.firstIndex(where: { $0.recipe.uuid == recipe.uuid }) {
            viewController = self.recipes[index]
            direction = index >= self.currentIndex ? .forward : .reverse
            self.currentIndex = index
        } else {
            viewController = CookingItemVC(recipe: recipe)
            direction = .forward
            self.currentIndex = self.recipes.count
            self.recipes.append(viewController)
        }
        self.title = recipe.title
        self.setViewControllers([viewController], direction: direction, animated: true)
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

        self.navigationItem.largeTitleDisplayMode = .never
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.dismissVC))

        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.view.backgroundColor = StyleGuide.colors.background
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
        } else {
            self.title = "Cooking"
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
