//
//  SceneDelegate.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/22/23.
//

import UIKit

protocol RBWindowSceneDelegate: UIWindowSceneDelegate {
    func sceneDidAddUser()
}

class SceneDelegate: UIResponder, RBWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // push navigation bar buttons closer to each other
        let stackViewAppearance = UIStackView.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
        stackViewAppearance.spacing = -4

        // TODO: check if the stored data version is older than the current version

        // load the stored app state
        if let error = State.manager.load() {
            // TODO: more sophisticated error handling is needed in the future
            print("ERROR: failed to load state: \(error.localizedDescription)")
        }
        // TEMPORARY: write back the state immediately in case we have cleared out an old version
        let _ = State.manager.store()

        // FIXME: DEBUG
        // State.manager.clear()
        // FIXME: END DEBUG

        self.window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        self.window?.windowScene = windowScene
        // check if the user has been registered
        if State.manager.userId.isEmpty {
            let vc = OnboardingVC()
            vc.sceneDelegate = self
            self.window?.rootViewController = vc
            self.window?.makeKeyAndVisible()
        } else {
            self.window?.rootViewController = RBTabBarController()
            self.window?.makeKeyAndVisible()
        }
    }

    func sceneDidAddUser() {
        guard let window = self.window else { return }

        window.rootViewController = RBTabBarController()
        UIView.transition(with: window, duration: 0.6, options: .transitionCrossDissolve, animations: {})
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}
