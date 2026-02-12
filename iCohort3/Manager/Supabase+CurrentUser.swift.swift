import Foundation
import Supabase

extension SupabaseManager {

    private struct PeopleAuthRow: Decodable {
        let id: String          // people.id (person_id)
        let authId: String?

        enum CodingKeys: String, CodingKey {
            case id
            case authId = "auth_id"
        }
    }

    /// Supabase Auth user UUID string
    func currentAuthId() async throws -> String {
        let session = try await client.auth.session
        return session.user.id.uuidString
    }

    /// people.id (person_id) for current Supabase user (auth_id -> people.id)
    func currentPersonId() async throws -> String {
        let authId = try await currentAuthId()

        let row: PeopleAuthRow = try await client
            .from("people")
            .select("id, auth_id")
            .eq("auth_id", value: authId)
            .single()
            .execute()
            .value

        // cache for fast reuse
        UserDefaults.standard.set(row.id, forKey: "current_person_id")

        return row.id
    }
}
