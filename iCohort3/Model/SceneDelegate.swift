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
        window.rootViewController = makeInitialRootViewController()
        window.makeKeyAndVisible()
        self.window = window
        
        print("✅ App initialization complete")
    }

    private func makeInitialRootViewController() -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        let shouldAutoLogin =
            UserDefaults.standard.bool(forKey: "remember_me") &&
            UserDefaults.standard.bool(forKey: "is_logged_in") &&
            !(UserDefaults.standard.string(forKey: "current_person_id") ?? "").isEmpty

        guard shouldAutoLogin else {
            let initialVC = storyboard.instantiateInitialViewController()!
            return initialVC
        }

        let role = UserDefaults.standard.string(forKey: "current_user_role")

        switch role {
        case "student":
            return MainTabBarViewController()
        case "mentor":
            return MentorMainTabBarViewController()
        default:
            let initialVC = storyboard.instantiateInitialViewController()!
            return initialVC
        }
    }
}
