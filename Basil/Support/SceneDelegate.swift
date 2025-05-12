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

        // Check if the stored state is outdated and synchronize accordingly
        self.synchronizeStoredData()
        // Then load application state from local storage
        State.manager.load()

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
        if !State.manager.userId.isEmpty {
            // Set the offline read-only mode flag until authentication has completed successfully
            State.manager.readOnly = true
            self.authenticate()
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

    func synchronizeStoredData() {
        if PersistenceManager.shared.dataVersion < PersistenceManager.version {
            // V1->V2: password is stored in keychain, users must be logged out in order to synchronize
            if PersistenceManager.shared.dataVersion == 1 {
                // Peek at the stored state to see if a user is logged in
                let storage = PersistenceManager.shared.state
                if !storage.userId.isEmpty {
                    let alert = GenericAlert(
                        title: "App updated",
                        message: "Important changes have been made behind the scenes, you must " +
                                 "log into your account again"
                    )
                    self.preUIAlerts.append(alert)
                    // Clear out the stored state
                    PersistenceManager.shared.deletePassword(email: storage.userEmail)
                    PersistenceManager.shared.state = .empty()
                }
            }
        }
        // Set data version to the current
        PersistenceManager.shared.dataVersion = PersistenceManager.version
    }

    func authenticate() {
        // Fetch the password from the keychain
        switch PersistenceManager.shared.fetchPassword(email: State.manager.userEmail) {
        case .success(let password):
            NetworkManager.authenticate(email: State.manager.userEmail, password: password) { (result) in
                switch result {
                case .success(let info):
                    // TODO: check if the stored data is outdated
                    // Open the WebSocket connection with the server
                    SocketManager.shared.connect(token: info.token)
                case .failure(let error):
                    DispatchQueue.main.async {
                        // Failed to ping server
                        self.window?.rootViewController?.presentErrorAlert(error)
                    }
                }
            }
        case .failure(let error):
            // TODO: failure to retrieve the password from the keychain should prompt the user
            // TODO: to re-enter their password or be logged out
            DispatchQueue.main.async {
                self.window?.rootViewController?.presentErrorAlert(error)
            }
        }
    }
}

extension SceneDelegate: SocketManager.Delegate {

    func didConnectToServer() {
        // Server communication successfully established
        State.manager.readOnly = false

        // FIXME: DEBUG
        print("connected to WebSocket server")
    }

    func didDisconnectFromServer(error: BasilError?) {
        // FIXME: DEBUG
        print("disconnected from WebSocket server: \(error?.title ?? ""): \(error?.message ?? "")")
    }

    func socketError(_ error: BasilError) {
        // FIXME: DEBUG
        print("WebSocket server error: \(error.title): \(error.message)")
    }
}
