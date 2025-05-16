//
//  SceneDelegate.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/22/23.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow? = nil
    // use this to register any alerts that are generated before the UI is presented
    var preUIAlerts: [UIAlertController] = []

    // Scene functions

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Attempt to load stored credentials from the keychain
        var credentials: KeychainManager.Credentials? = nil
        do {
            credentials = try KeychainManager.getCredentials()
        } catch {
            let alert = ErrorAlert(error: error as! BasilError)
            self.preUIAlerts.append(alert)
        }

        // Check if the stored state is outdated and synchronize accordingly
        self.synchronizeStoredData(credentials: credentials)
        // Then load application state from local storage
        State.manager.load()
        State.manager.userEmail = credentials?.email ?? ""

        // Create the application window
        self.window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        self.window?.windowScene = windowScene
        self.window?.rootViewController = TabBarController()
        self.window?.makeKeyAndVisible()

        // Present any alerts that were generated before the main window was presented
        for alert in self.preUIAlerts {
            self.window?.rootViewController?.present(alert, animated: true)
        }

        // Register the scene as a delegate for the WebSocket handler
        SocketManager.shared.addDelegate(self)

        // If an account is logged in, authenticate with the server
        if let credentials {
            // Set the offline read-only mode flag until authentication has completed successfully
            State.manager.readOnly = true
            self.authenticate(credentials: credentials)
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
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        UserDefaults.standard.synchronize()
    }

    // Helper functions

    func synchronizeStoredData(credentials: KeychainManager.Credentials?) {
        if PersistenceManager.shared.dataVersion < PersistenceManager.version {
            // V1->V2: removed `state` from PersistenceManager keys and split out into individual fields
            if PersistenceManager.shared.dataVersion == 1 {
                let stored: State.Storage__V1 = PersistenceManager.shared.getObject(
                    forKey: PersistenceManager.Keys.state, defaultValue: .empty()
                )
                PersistenceManager.shared.root = stored.root
                PersistenceManager.shared.recipes = stored.recipes
                PersistenceManager.shared.folders = stored.folders
                // Clear out the keychain to log out the user
                do { try KeychainManager.deleteCredentials() } catch {}
                // and alert them to that fact
                let alert = GenericAlert(
                    title: "App updated",
                    message: "Important changes have been made behind the scenes, you must " +
                             "log into your account again"
                )
                self.preUIAlerts.append(alert)
            }
        }
        // Set data version to the current
        PersistenceManager.shared.dataVersion = PersistenceManager.version
    }

    func authenticate(credentials: KeychainManager.Credentials) {
        NetworkManager.authenticate(email: credentials.email, password: credentials.password) { (result) in
            switch result {
            case .success(let info):
                // Check if the local copy of the recipes is outdated
                if info.sequence > State.manager.sequence {
                    State.manager.addUserInfo(info: info)
                    // Signal to any recipe list views to reload their state
                    DispatchQueue.main.async {
                        let tabBarController = self.window?.rootViewController as! TabBarController
                        tabBarController.refreshRecipeLists()
                    }
                }
                // Open the WebSocket connection with the server
                SocketManager.shared.connect(userId: info.id, token: info.token)
            case .failure(let error):
                DispatchQueue.main.async {
                    // Failed to ping server
                    self.window?.rootViewController?.presentErrorAlert(error)
                }
            }
        }
    }
}

extension SceneDelegate: SocketManager.Delegate {

    func didConnectToServer() {
        // Server communication successfully established
        State.manager.readOnly = false
    }

    func didPushToServer() {
        // Server update successful, bump the sequence count
        State.manager.sequence += 1
    }

    func socketError(_ error: BasilError) {
        // Server communication error, set the offline read-only mode flag until server
        // communication can be re-established
        State.manager.readOnly = true

        DispatchQueue.main.async {
            self.window?.rootViewController?.presentErrorAlert(error)
        }
    }
}
