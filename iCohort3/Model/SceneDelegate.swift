import UIKit
import FirebaseCore
import FirebaseFirestore

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        print("🚀 Initializing Firebase...")
        
        // Initialize Firebase FIRST
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("✅ Firebase configured")
        } else {
            print("✅ Firebase already configured")
        }
        
        // Test Firestore connection
        Task {
            do {
                let db = Firestore.firestore()
                _ = try await db.collection("test").limit(to: 1).getDocuments()
                print("✅ Firestore connection successful")
            } catch {
                print("❌ Firestore connection failed:", error)
            }
        }
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let initialVC = storyboard.instantiateInitialViewController()!
        
        window.rootViewController = initialVC
        window.makeKeyAndVisible()
        self.window = window
        
        print("✅ App initialization complete")
    }
}
