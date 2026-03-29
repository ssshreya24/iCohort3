import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = makeInitialRootViewController()
        window.makeKeyAndVisible()
        self.window = window
        
        print("✅ App initialization complete")
    }

    private func makeInitialRootViewController() -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let rememberMeEnabled = UserDefaults.standard.bool(forKey: "remember_me")
        let isLoggedIn = UserDefaults.standard.bool(forKey: "is_logged_in")
        let role = UserDefaults.standard.string(forKey: "current_user_role")
        let hasPersonSession = !(UserDefaults.standard.string(forKey: "current_person_id") ?? "").isEmpty
        let hasAdminSession = !(UserDefaults.standard.string(forKey: "admin_email") ?? "").isEmpty
        let shouldAutoLogin =
            rememberMeEnabled &&
            isLoggedIn &&
            ((role == "admin" && hasAdminSession) || hasPersonSession)

        guard shouldAutoLogin else {
            let initialVC = storyboard.instantiateInitialViewController()!
            return initialVC
        }

        switch role {
        case "student":
            return MainTabBarViewController()
        case "mentor":
            return MentorMainTabBarViewController()
        case "admin":
            return UINavigationController(rootViewController: AdminDashboardViewController())
        default:
            let initialVC = storyboard.instantiateInitialViewController()!
            return initialVC
        }
    }
}
