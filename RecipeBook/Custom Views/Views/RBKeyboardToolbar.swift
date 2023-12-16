//
//  RBKeyboardToolbar.swift
//  RecipeBook
//
//  Created by Ian Brault on 12/8/23.
//

import UIKit

protocol RBKeyboardToolbarDelegate: AnyObject {
    func previousButtonPressed()
    func nextButtonPressed()
    func doneButtonPressed()
}

class RBKeyboardToolbar: UIToolbar {

    var previousButton: UIBarButtonItem!
    var nextButton: UIBarButtonItem!
    var doneButton: UIBarButtonItem!

    weak var toolbarDelegate: RBKeyboardToolbarDelegate?

    init(width: CGFloat, height: CGFloat) {
        super.init(frame: CGRect(x: 0, y: 0, width: width, height: height))

        self.previousButton = UIBarButtonItem(
            image: SFSymbols.arrowUp, style: .plain, target: self, action: #selector(self.previousButtonPressed))

        self.nextButton = UIBarButtonItem(
            image: SFSymbols.arrowDown, style: .plain, target: self, action: #selector(self.nextButtonPressed))

        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        self.doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.doneButtonPressed))

        self.items = [self.previousButton, self.nextButton, spacer, self.doneButton]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func previousButtonPressed() {
        self.toolbarDelegate?.previousButtonPressed()
    }

    @objc func nextButtonPressed() {
        self.toolbarDelegate?.nextButtonPressed()
    }

    @objc func doneButtonPressed() {
        self.toolbarDelegate?.doneButtonPressed()
    }
}
