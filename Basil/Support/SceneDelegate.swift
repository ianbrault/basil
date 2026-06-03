//
//  SceneDelegate.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/22/23.
//

import UIKit
import os

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: SceneDelegate.self)
    )

    var window: UIWindow? = nil
    // Use this to register any alerts that are generated before the UI is presented
    var preUIAlerts: [UIAlertController] = []
    // Mark after the app has booted, use to determine when to re-connect to the server
    var hasBooted = false

    // Scene functions

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        Self.logger.trace("Creating scene")

        // Attempt to load stored credentials from the keychain
        var credentials: Keychain.Credentials? = nil
        do {
            credentials = try Keychain.getCredentials()
        } catch let error {
            Self.logger.error(
                "Error retrieving credentials from keychain: \(error)"
            )
            // Notify the user that they are logged out due to the keychain error
            let alert = GenericAlert(
                title: "Keychain Error",
                message:
                    "An error occurred while retrieving your password, please log in to your account again"
            )
            self.preUIAlerts.append(alert)
        }

        // Check if the stored state is outdated and synchronize accordingly
        self.synchronizeStoredData(credentials: credentials)
        // Then load application state from local storage
        StateManager.shared.load()

        // Create the application window
        self.window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        self.window?.windowScene = windowScene
        self.window?.rootViewController = TabBarController()
        self.window?.makeKeyAndVisible()

        // Present any alerts that were generated before the main window was presented
        for alert in self.preUIAlerts {
            self.window?.rootViewController?.present(alert, animated: true)
        }

        // If an account is logged in, authenticate with the server
        // Validate that the stored credentials matches the stored state
        if let credentials {
            if credentials.email == StateManager.shared.userEmail {
                self.authenticate(credentials: credentials)
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded
        // (see `application:didDiscardSceneSessions` instead).
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
        if !self.hasBooted {
            self.hasBooted = true
            return
        }

        // Re-connect to the server, if authenticated
        if let credentials = try? Keychain.getCredentials() {
            self.authenticate(credentials: credentials)
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Synchronize changes made to PersistenceManager with the backing storage
        UserDefaults.standard.synchronize()
    }

    // Helper functions

    func synchronizeStoredData(credentials: Keychain.Credentials?) {
        if PersistenceManager.shared.dataVersion < PersistenceManager.version {
            // TODO: unimplemented...
        }
        // Set data version to the current
        PersistenceManager.shared.dataVersion = PersistenceManager.version
    }

    func authenticate(credentials: Keychain.Credentials) {
        Self.logger.info("Authenticating user \(credentials.email)")
        Task { [weak self] in
            do {
                try await StateManager.shared.authenticateUser(
                    email: credentials.email,
                    password: credentials.password,
                    addToKeychain: false  // password already came from the keychain
                )
                // Signal to any recipe list views to reload their state
                DispatchQueue.main.async {
                    let tabBarController =
                        self?.window?.rootViewController as! TabBarController
                    tabBarController.refreshRecipeLists()
                }
            } catch let error {
                // Failed to ping server
                DispatchQueue.main.async {
                    self?.window?.rootViewController?.presentErrorAlert(error)
                }
            }
        }
    }
}
