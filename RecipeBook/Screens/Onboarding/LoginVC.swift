//
//  LoginVC.swift
//  RecipeBook
//
//  Created by Ian Brault on 11/16/23.
//

import UIKit

class LoginVC: UIViewController {

    weak var delegate: OnboardingVCDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBlue
    }
}
