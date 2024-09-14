//
//  UIWindow+Ext.swift
//  RecipeBook
//
//  Created by Ian Brault on 9/14/24.
//

import UIKit

extension UIWindow {
    
    class TransitionOptions: NSObject, CAAnimationDelegate {

        enum Curve {
            case linear
            case easeIn
            case easeOut
            case easeInOut

            internal var function: CAMediaTimingFunction {
                switch self {
                case .linear:
                    return CAMediaTimingFunction(name: .linear)
                case .easeIn:
                    return CAMediaTimingFunction(name: .easeIn)
                case .easeOut:
                    return CAMediaTimingFunction(name: .easeOut)
                case .easeInOut:
                    return CAMediaTimingFunction(name: .easeInEaseOut)
                }
            }
        }

        enum Direction {
            case fade
            case toTop
            case toBottom
            case toLeft
            case toRight

            internal func transition() -> CATransition {
                let transition = CATransition()
                transition.type = CATransitionType.push
                switch self {
                case .fade:
                    transition.type = CATransitionType.fade
                    transition.subtype = nil
                case .toLeft:
                    transition.subtype = CATransitionSubtype.fromLeft
                case .toRight:
                    transition.subtype = CATransitionSubtype.fromRight
                case .toTop:
                    transition.subtype = CATransitionSubtype.fromTop
                case .toBottom:
                    transition.subtype = CATransitionSubtype.fromBottom
                }
                return transition
            }
        }

        enum Background {
            case snapshot
            case solidColor(_: UIColor)
            case customView(_: UIView)
        }

        var duration: TimeInterval = 0.32
        var direction: TransitionOptions.Direction = .toRight
        var style: TransitionOptions.Curve = .linear
        var background: TransitionOptions.Background? = .solidColor(StyleGuide.colors.background)
        weak var previousController: UIViewController?

        init(direction: TransitionOptions.Direction = .toRight, style: TransitionOptions.Curve = .linear) {
            self.direction = direction
            self.style = style
        }

        internal var animation: CATransition {
            let transition = self.direction.transition()
            transition.duration = self.duration
            transition.timingFunction = self.style.function
            transition.delegate = self
            return transition
        }

        func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
            let controller = self.previousController as? UINavigationController
            controller?.viewControllers = []  // temporary hack
        }
    }

    func setRootViewController(_ newController: UIViewController, options: TransitionOptions = TransitionOptions()) {
        let previousController = self.rootViewController

        self.layer.add(options.animation, forKey: kCATransition)
        options.previousController = self.rootViewController

        self.rootViewController = newController

        // update status bar appearance using the new view controller appearance - animate if needed
        if UIView.areAnimationsEnabled {
            UIView.animate(withDuration: CATransaction.animationDuration()) {
                newController.setNeedsStatusBarAppearanceUpdate()
            }
        } else {
            newController.setNeedsStatusBarAppearanceUpdate()
        }

        if let previousController {
            // allow the view controller to be deallocated
            previousController.dismiss(animated: false) {
                // remove the root view in case it is still showing
                previousController.view.removeFromSuperview()
            }
        }
    }
}
