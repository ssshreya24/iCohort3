import UIKit

// Temporary DEBUG-only auth helper for local QA.
// Safe to delete once OTP testing is no longer needed.
enum TestingPurpose {
    struct DebugLoginSession {
        let role: SupabaseManager.LoginOTPUserRole
        let email: String
        let personId: String?
        let displayName: String
        let instituteName: String?
        let instituteDomain: String?
    }

    static func attemptDebugLogin(
        email: String,
        password: String,
        role: SupabaseManager.LoginOTPUserRole
    ) async throws -> DebugLoginSession? {
#if DEBUG
        guard matchesTestingCredentials(email: email, password: password, role: role) else {
            return nil
        }

        switch role {
        case .student:
            guard let personId = try await SupabaseManager.shared.fetchStudentId(srmMail: email) else {
                throw NSError(
                    domain: "TestingPurpose",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Testing student account could not be resolved."]
                )
            }

            let profile = try await SupabaseManager.shared.fetchBasicStudentProfile(personId: personId)
            return DebugLoginSession(
                role: .student,
                email: email,
                personId: personId,
                displayName: resolvedDisplayName(
                    firstName: profile?.first_name,
                    lastName: profile?.last_name,
                    fallbackEmail: email,
                    fallbackLabel: "Student"
                ),
                instituteName: nil,
                instituteDomain: nil
            )

        case .mentor:
            guard let personId = try await SupabaseManager.shared.fetchMentorId(email: email) else {
                throw NSError(
                    domain: "TestingPurpose",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Testing mentor account could not be resolved."]
                )
            }

            let profile = try await SupabaseManager.shared.fetchBasicMentorProfile(personId: personId)
            return DebugLoginSession(
                role: .mentor,
                email: email,
                personId: personId,
                displayName: resolvedDisplayName(
                    firstName: profile?.first_name,
                    lastName: profile?.last_name,
                    fallbackEmail: email,
                    fallbackLabel: "Mentor"
                ),
                instituteName: nil,
                instituteDomain: nil
            )

        case .admin:
            guard let institute = try await SupabaseManager.shared.getInstitute(byAdminEmail: email) else {
                throw NSError(
                    domain: "TestingPurpose",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Testing admin account could not be resolved."]
                )
            }

            return DebugLoginSession(
                role: .admin,
                email: email,
                personId: nil,
                displayName: "Admin",
                instituteName: institute.name,
                instituteDomain: institute.domain
            )
        }
#else
        return nil
#endif
    }

    @MainActor
    static func completeDebugLogin(
        _ session: DebugLoginSession,
        shouldRemember: Bool,
        from viewController: UIViewController
    ) {
        let defaults = UserDefaults.standard

        defaults.set(session.displayName, forKey: "current_user_name")
        defaults.set(session.email, forKey: "current_user_email")
        defaults.set(session.role.rawValue, forKey: "current_user_role")
        defaults.set(true, forKey: "is_logged_in")

        switch session.role {
        case .student:
            defaults.set(session.personId, forKey: "current_person_id")
            defaults.removeObject(forKey: "admin_email")
            defaults.removeObject(forKey: "admin_institute_name")
            defaults.removeObject(forKey: "admin_institute_domain")
            defaults.set(false, forKey: "is_admin")
            applyRememberMePreference(shouldRemember: shouldRemember, email: session.email, role: session.role.rawValue)
            transition(to: MainTabBarViewController(), from: viewController)

        case .mentor:
            defaults.set(session.personId, forKey: "current_person_id")
            defaults.removeObject(forKey: "admin_email")
            defaults.removeObject(forKey: "admin_institute_name")
            defaults.removeObject(forKey: "admin_institute_domain")
            defaults.set(false, forKey: "is_admin")
            applyRememberMePreference(shouldRemember: shouldRemember, email: session.email, role: session.role.rawValue)
            transition(to: MentorMainTabBarViewController(), from: viewController)

        case .admin:
            defaults.removeObject(forKey: "current_person_id")
            defaults.set(session.email, forKey: "admin_email")
            defaults.set(session.instituteName, forKey: "admin_institute_name")
            defaults.set(session.instituteDomain, forKey: "admin_institute_domain")
            defaults.set(true, forKey: "is_admin")
            applyRememberMePreference(shouldRemember: shouldRemember, email: session.email, role: session.role.rawValue)
            transition(to: UINavigationController(rootViewController: AdminDashboardViewController()), from: viewController)
        }
    }

    private static func matchesTestingCredentials(
        email: String,
        password: String,
        role: SupabaseManager.LoginOTPUserRole
    ) -> Bool {
#if DEBUG
        switch role {
        case .student, .mentor:
            return email == "lp9013@srmist.edu.in" && password == "asdfghjkl"
        case .admin:
            return email == "lakshyp06@gmail.com" && password == "Test@1234"
        }
#else
        return false
#endif
    }

    private static func resolvedDisplayName(
        firstName: String?,
        lastName: String?,
        fallbackEmail: String,
        fallbackLabel: String
    ) -> String {
        let parts = [firstName, lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if !parts.isEmpty {
            return parts.joined(separator: " ")
        }

        let emailPrefix = fallbackEmail.split(separator: "@").first.map(String.init) ?? fallbackLabel
        return emailPrefix.isEmpty ? fallbackLabel : emailPrefix
    }

    private static func applyRememberMePreference(shouldRemember: Bool, email: String, role: String) {
        let defaults = UserDefaults.standard

        if shouldRemember {
            defaults.set(true, forKey: "remember_me")
            defaults.set(email, forKey: "remembered_email")
            defaults.set(role, forKey: "remembered_user_role")
        } else {
            defaults.set(false, forKey: "remember_me")
            defaults.removeObject(forKey: "remembered_email")
            defaults.removeObject(forKey: "remembered_user_role")
        }
    }

    @MainActor
    private static func transition(to viewController: UIViewController, from sourceViewController: UIViewController) {
        let window = sourceViewController.view.window ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }

        guard let window else { return }

        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.rootViewController = viewController
        }
    }
}
