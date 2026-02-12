import Foundation
import Supabase
import UIKit

final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        let url = URL(string: "https://jcengntlnilevfbsnswh.supabase.co")!
        let key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpjZW5nbnRsbmlsZXZmYnNuc3doIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM0Mzc5OTcsImV4cCI6MjA3OTAxMzk5N30.XOHB4ld2o__8JBFb6Z2W0bUf4nHDl5Q7b3nNDA2Kml8"

        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key
        )
    }

    // MARK: - Image helpers

    func imageToBase64(image: UIImage, maxSizeKB: Int = 500) -> String? {
        var compressionQuality: CGFloat = 0.8
        var imageData = image.jpegData(compressionQuality: compressionQuality)

        let maxSize = maxSizeKB * 1024
        while let data = imageData, data.count > maxSize && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            imageData = image.jpegData(compressionQuality: compressionQuality)
        }

        guard let finalData = imageData else { return nil }
        return finalData.base64EncodedString()
    }

    func base64ToImage(base64String: String) -> UIImage? {
        guard let imageData = Data(base64Encoded: base64String) else { return nil }
        return UIImage(data: imageData)
    }

    func detectFileType(filename: String) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "pdf": return "application/pdf"
        default: return "image/jpeg"
        }
    }

    func createLinkPlaceholderImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            UIColor.systemBlue.withAlphaComponent(0.1).setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let iconConfig = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
            let linkIcon = UIImage(systemName: "link", withConfiguration: iconConfig)
            linkIcon?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
                .draw(in: CGRect(x: 30, y: 30, width: 40, height: 40))
        }

        return image
    }
}

// MARK: - Models

extension SupabaseManager {

    struct StudentProfileCompleteRow: Identifiable, Decodable, Hashable {
        var id: String { personId }

        let personId: String
        let fullName: String?
        let firstName: String?
        let lastName: String?
        let regNo: String?
        let department: String?
        let isProfileComplete: Bool?
        let teamId: String?
        let teamNo: Int?

        enum CodingKeys: String, CodingKey {
            case personId = "person_id"
            case fullName = "full_name"
            case firstName = "first_name"
            case lastName = "last_name"
            case regNo = "reg_no"
            case department
            case isProfileComplete = "is_profile_complete"
            case teamId = "team_id"
            case teamNo = "team_no"
        }

        var displayName: String {
            let f = (fullName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !f.isEmpty { return f }

            let first = (firstName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let last  = (lastName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let built = "\(first) \(last)".trimmingCharacters(in: .whitespacesAndNewlines)
            return built.isEmpty ? "Student" : built
        }
    }

    struct TeamMemberRequestRow: Decodable {
        let id: UUID
        let fromStudentId: String
        let fromStudentName: String
        let toStudentId: String
        let toStudentName: String
        let status: String
        let createdAt: String?

        enum CodingKeys: String, CodingKey {
            case id
            case fromStudentId = "from_student_id"
            case fromStudentName = "from_student_name"
            case toStudentId = "to_student_id"
            case toStudentName = "to_student_name"
            case status
            case createdAt = "created_at"
        }
    }

    struct InsertTeamMemberRequestRow: Encodable {
        let fromStudentId: String
        let fromStudentName: String
        let toStudentId: String
        let toStudentName: String
        let status: String

        enum CodingKeys: String, CodingKey {
            case fromStudentId = "from_student_id"
            case fromStudentName = "from_student_name"
            case toStudentId = "to_student_id"
            case toStudentName = "to_student_name"
            case status
        }

        init(fromStudentId: String, fromStudentName: String, toStudentId: String, toStudentName: String) {
            self.fromStudentId = fromStudentId
            self.fromStudentName = fromStudentName
            self.toStudentId = toStudentId
            self.toStudentName = toStudentName
            self.status = "pending"
        }
    }
}

// MARK: - Name Fetch (ONLY student_profile_complete via person_id)

extension SupabaseManager {

    private struct FullNameOnlyRow: Decodable {
        let fullName: String?
        enum CodingKeys: String, CodingKey { case fullName = "full_name" }
    }

    private struct FirstLastRow: Decodable {
        let firstName: String?
        let lastName: String?
        enum CodingKeys: String, CodingKey {
            case firstName = "first_name"
            case lastName  = "last_name"
        }
    }

    private struct PersonIdOnlyRow: Decodable {
        let personId: String
        enum CodingKeys: String, CodingKey { case personId = "person_id" }
    }

    func fetchStudentFullName(personIdString: String) async throws -> String {
        let rows: [FullNameOnlyRow] = try await self.client
            .from("student_profile_complete")
            .select("full_name")
            .eq("person_id", value: personIdString)
            .limit(1)
            .execute()
            .value

        let full = (rows.first?.fullName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !full.isEmpty { return full }

        let rows2: [FirstLastRow] = try await self.client
            .from("student_profile_complete")
            .select("first_name,last_name")
            .eq("person_id", value: personIdString)
            .limit(1)
            .execute()
            .value

        let first = (rows2.first?.firstName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let last  = (rows2.first?.lastName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let built = "\(first) \(last)".trimmingCharacters(in: .whitespacesAndNewlines)

        if !built.isEmpty { return built }

        throw NSError(
            domain: "student_profile_complete",
            code: -404,
            userInfo: [NSLocalizedDescriptionKey: "Name not found for person_id=\(personIdString)"]
        )
    }

    private func resolveStudentName(personIdString: String, fallback: String?) async throws -> String {
        if let n = try? await fetchStudentFullName(personIdString: personIdString) {
            let cleaned = n.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleaned.isEmpty { return cleaned }
        }

        let fb = (fallback ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !fb.isEmpty { return fb }

        throw NSError(
            domain: "student_profile_complete",
            code: -405,
            userInfo: [NSLocalizedDescriptionKey: "Unable to resolve name for person_id=\(personIdString)"]
        )
    }

    func ensureStudentProfileExists(personIdString: String) async throws {
        let rows: [PersonIdOnlyRow] = try await self.client
            .from("student_profile_complete")
            .select("person_id")
            .eq("person_id", value: personIdString)
            .limit(1)
            .execute()
            .value

        if rows.first == nil {
            throw NSError(
                domain: "student_profile_complete",
                code: -406,
                userInfo: [NSLocalizedDescriptionKey: "student_profile_complete row not found for person_id=\(personIdString)"]
            )
        }
    }
}

// MARK: - Student List (✅ only is_profile_complete = true, no team)

extension SupabaseManager {

    func fetchInvitableStudents(excludingPersonIdString personIdString: String) async throws -> [StudentProfileCompleteRow] {
        let rows: [StudentProfileCompleteRow] = try await self.client
            .from("student_profile_complete")
            .select("person_id,full_name,first_name,last_name,reg_no,department,is_profile_complete,team_id,team_no")
            .eq("is_profile_complete", value: true)
            .is("team_id", value: nil)
            .is("team_no", value: nil)
            .neq("person_id", value: personIdString)
            .order("full_name", ascending: true)
            .execute()
            .value

        return rows
    }
}

// MARK: - Requests

extension SupabaseManager {

    func sendTeamMemberRequest(fromId: String, fromName: String, toId: String, toName: String) async throws {
        let payload = InsertTeamMemberRequestRow(
            fromStudentId: fromId,
            fromStudentName: fromName,
            toStudentId: toId,
            toStudentName: toName
        )

        _ = try await self.client
            .from("team_member_requests")
            .insert(payload)
            .execute()
    }

    func fetchIncomingRequests(for personIdString: String) async throws -> [TeamMemberRequestRow] {
        let rows: [TeamMemberRequestRow] = try await self.client
            .from("team_member_requests")
            .select("id,from_student_id,from_student_name,to_student_id,to_student_name,status,created_at")
            .eq("to_student_id", value: personIdString)
            .eq("status", value: "pending")
            .order("created_at", ascending: false)
            .execute()
            .value
        return rows
    }

    func fetchSentRequests(from personIdString: String) async throws -> [TeamMemberRequestRow] {
        let rows: [TeamMemberRequestRow] = try await self.client
            .from("team_member_requests")
            .select("id,from_student_id,from_student_name,to_student_id,to_student_name,status,created_at")
            .eq("from_student_id", value: personIdString)
            .eq("status", value: "pending")
            .order("created_at", ascending: false)
            .execute()
            .value
        return rows
    }

    private func updateRequestStatus(requestId: UUID, status: String) async throws {
        struct Update: Encodable { let status: String }

        _ = try await self.client
            .from("team_member_requests")
            .update(Update(status: status))
            .eq("id", value: requestId.uuidString)
            .execute()
    }

    private func fetchRequestById(_ requestId: UUID) async throws -> TeamMemberRequestRow? {
        let rows: [TeamMemberRequestRow] = try await self.client
            .from("team_member_requests")
            .select("id,from_student_id,from_student_name,to_student_id,to_student_name,status,created_at")
            .eq("id", value: requestId.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first
    }
}

// MARK: - new_teams

extension SupabaseManager {

    struct NewTeamRow: Decodable {
        let id: UUID
        let teamNumber: Int
        let createdById: String
        let createdByName: String
        let member2Id: String?
        let member2Name: String?
        let member3Id: String?
        let member3Name: String?
        let mentorId: String?
        let mentorName: String?
        let status: String
        let createdAt: String?

        enum CodingKeys: String, CodingKey {
            case id
            case teamNumber = "team_number"
            case createdById = "created_by_id"
            case createdByName = "created_by_name"
            case member2Id = "member2_id"
            case member2Name = "member2_name"
            case member3Id = "member3_id"
            case member3Name = "member3_name"
            case mentorId = "mentor_id"
            case mentorName = "mentor_name"
            case status
            case createdAt = "created_at"
        }
    }

    struct NewTeamInsert: Encodable {
        let createdById: String
        let createdByName: String
        let status: String

        enum CodingKeys: String, CodingKey {
            case createdById = "created_by_id"
            case createdByName = "created_by_name"
            case status
        }
    }

    struct NewTeamUpdate: Encodable {
        let member2Id: String?
        let member2Name: String?
        let member3Id: String?
        let member3Name: String?

        enum CodingKeys: String, CodingKey {
            case member2Id = "member2_id"
            case member2Name = "member2_name"
            case member3Id = "member3_id"
            case member3Name = "member3_name"
        }
    }

    func fetchActiveTeamForUser(userId: String) async throws -> NewTeamRow? {
        let filter = "created_by_id.eq.\(userId),member2_id.eq.\(userId),member3_id.eq.\(userId)"

        let result: [NewTeamRow] = try await self.client
            .from("new_teams")
            .select("id,team_number,created_by_id,created_by_name,member2_id,member2_name,member3_id,member3_name,mentor_id,mentor_name,status,created_at")
            .eq("status", value: "active")
            .or(filter)
            .limit(1)
            .execute()
            .value

        return result.first
    }

    func createTeamIfNone(personIdString: String, fallbackUserName: String? = nil) async throws -> NewTeamRow {
        if let existing = try await fetchActiveTeamForUser(userId: personIdString) {
            return existing
        }

        try await ensureStudentProfileExists(personIdString: personIdString)

        let createdByName = try await resolveStudentName(
            personIdString: personIdString,
            fallback: fallbackUserName
        )

        let payload = NewTeamInsert(
            createdById: personIdString,
            createdByName: createdByName,
            status: "active"
        )

        do {
            let created: [NewTeamRow] = try await self.client
                .from("new_teams")
                .insert(payload)
                .select("id,team_number,created_by_id,created_by_name,member2_id,member2_name,member3_id,member3_name,mentor_id,mentor_name,status,created_at")
                .execute()
                .value

            guard let row = created.first else {
                throw NSError(domain: "new_teams", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Team creation failed: no row returned"])
            }

            // Update student_profile_complete with team info
            try await updateStudentTeamInfo(personId: personIdString, teamId: row.id, teamNo: row.teamNumber)

            return row
        } catch {
            if let existingAfterFail = try? await fetchActiveTeamForUser(userId: personIdString) {
                return existingAfterFail
            }
            throw error
        }
    }

    func deleteTeam(teamId: UUID, creatorId: String) async throws {
        // First fetch the team to get all member IDs
        let team: [NewTeamRow] = try await self.client
            .from("new_teams")
            .select("id,team_number,created_by_id,member2_id,member3_id")
            .eq("id", value: teamId.uuidString)
            .eq("created_by_id", value: creatorId)
            .execute()
            .value
        
        guard let teamRow = team.first else {
            throw NSError(domain: "new_teams", code: -6,
                          userInfo: [NSLocalizedDescriptionKey: "Team not found or you're not the creator"])
        }
        
        // Clear team info from all members
        var memberIds = [teamRow.createdById]
        if let m2 = teamRow.member2Id { memberIds.append(m2) }
        if let m3 = teamRow.member3Id { memberIds.append(m3) }
        
        for memberId in memberIds {
            try? await clearStudentTeamInfo(personId: memberId)
        }
        
        // Delete the team
        _ = try await self.client
            .from("new_teams")
            .delete()
            .eq("id", value: teamId.uuidString)
            .eq("created_by_id", value: creatorId)
            .execute()
    }

    func leaveTeam(team: NewTeamRow, userId: String) async throws {
        if team.createdById == userId {
            throw NSError(domain: "new_teams", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "Creator cannot leave. Delete the team instead."])
        }

        if team.member2Id == userId {
            let update = NewTeamUpdate(
                member2Id: nil, member2Name: nil,
                member3Id: team.member3Id, member3Name: team.member3Name
            )
            _ = try await self.client.from("new_teams").update(update).eq("id", value: team.id.uuidString).execute()
            
            // Clear team info from student profile
            try await clearStudentTeamInfo(personId: userId)
            return
        }

        if team.member3Id == userId {
            let update = NewTeamUpdate(
                member2Id: team.member2Id, member2Name: team.member2Name,
                member3Id: nil, member3Name: nil
            )
            _ = try await self.client.from("new_teams").update(update).eq("id", value: team.id.uuidString).execute()
            
            // Clear team info from student profile
            try await clearStudentTeamInfo(personId: userId)
            return
        }

        throw NSError(domain: "new_teams", code: -3,
                      userInfo: [NSLocalizedDescriptionKey: "You are not a member of this team"])
    }

    func addMemberToTeam(team: NewTeamRow, memberId: String, memberName: String) async throws {
        if team.createdById == memberId || team.member2Id == memberId || team.member3Id == memberId {
            throw NSError(domain: "new_teams", code: -4,
                          userInfo: [NSLocalizedDescriptionKey: "Already in this team"])
        }

        if team.member2Id == nil {
            let update = NewTeamUpdate(
                member2Id: memberId, member2Name: memberName,
                member3Id: team.member3Id, member3Name: team.member3Name
            )
            _ = try await self.client.from("new_teams").update(update).eq("id", value: team.id.uuidString).execute()
            
            // Update student profile with team info
            try await updateStudentTeamInfo(personId: memberId, teamId: team.id, teamNo: team.teamNumber)
            return
        }

        if team.member3Id == nil {
            let update = NewTeamUpdate(
                member2Id: team.member2Id, member2Name: team.member2Name,
                member3Id: memberId, member3Name: memberName
            )
            _ = try await self.client.from("new_teams").update(update).eq("id", value: team.id.uuidString).execute()
            
            // Update student profile with team info
            try await updateStudentTeamInfo(personId: memberId, teamId: team.id, teamNo: team.teamNumber)
            return
        }

        throw NSError(domain: "new_teams", code: -5,
                      userInfo: [NSLocalizedDescriptionKey: "Team is full"])
    }
    
    // MARK: - Student Profile Team Info Management
    
    private struct StudentTeamUpdate: Encodable {
        let teamId: String?
        let teamNo: Int?
        
        enum CodingKeys: String, CodingKey {
            case teamId = "team_id"
            case teamNo = "team_no"
        }
    }
    
    private func updateStudentTeamInfo(personId: String, teamId: UUID, teamNo: Int) async throws {
        let update = StudentTeamUpdate(teamId: teamId.uuidString, teamNo: teamNo)
        
        _ = try await self.client
            .from("student_profile_complete")
            .update(update)
            .eq("person_id", value: personId)
            .execute()
    }
    
    private func clearStudentTeamInfo(personId: String) async throws {
        let update = StudentTeamUpdate(teamId: nil, teamNo: nil)
        
        _ = try await self.client
            .from("student_profile_complete")
            .update(update)
            .eq("person_id", value: personId)
            .execute()
    }
}

// MARK: - Accept Request

extension SupabaseManager {

    func acceptTeamMemberRequest(requestId: UUID, receiverId: String, receiverName: String? = nil) async throws {

        guard let req = try await fetchRequestById(requestId) else {
            throw NSError(domain: "team_member_requests", code: -10,
                          userInfo: [NSLocalizedDescriptionKey: "Request not found"])
        }

        guard req.toStudentId == receiverId else {
            throw NSError(domain: "team_member_requests", code: -11,
                          userInfo: [NSLocalizedDescriptionKey: "Not authorized to accept this request"])
        }

        guard req.status == "pending" else {
            throw NSError(domain: "team_member_requests", code: -12,
                          userInfo: [NSLocalizedDescriptionKey: "Request already processed"])
        }

        if let _ = try await fetchActiveTeamForUser(userId: receiverId) {
            throw NSError(domain: "new_teams", code: -13,
                          userInfo: [NSLocalizedDescriptionKey: "You already have an active team"])
        }

        let requesterIdString = req.fromStudentId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard UUID(uuidString: requesterIdString) != nil else {
            throw NSError(domain: "team_member_requests", code: -14,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid requester person_id"])
        }

        let team = try await createTeamIfNone(personIdString: requesterIdString, fallbackUserName: req.fromStudentName)

        var finalReceiverName = (receiverName ?? req.toStudentName).trimmingCharacters(in: .whitespacesAndNewlines)
        if finalReceiverName.isEmpty {
            finalReceiverName = try await resolveStudentName(personIdString: receiverId, fallback: req.toStudentName)
        }

        if finalReceiverName.isEmpty {
            throw NSError(domain: "team_member_requests", code: -15,
                          userInfo: [NSLocalizedDescriptionKey: "Receiver name empty"])
        }

        try await addMemberToTeam(team: team, memberId: receiverId, memberName: finalReceiverName)
        try await updateRequestStatus(requestId: requestId, status: "accepted")
    }
}

// MARK: - Join Teams list support (expects UUID person_id)

extension SupabaseManager {

    struct JoinableStudentProfileRow: Decodable {
        let personId: UUID
        let fullName: String?
        let regNo: String?
        let department: String?
        let isProfileComplete: Bool?

        enum CodingKeys: String, CodingKey {
            case personId = "person_id"
            case fullName = "full_name"
            case regNo = "reg_no"
            case department
            case isProfileComplete = "is_profile_complete"
        }
    }

    /// Used by JoinTeamsViewController (expects UUID)
    func fetchAllStudents(excluding uid: UUID) async throws -> [JoinableStudentProfileRow] {
        let rows: [JoinableStudentProfileRow] = try await self.client
            .from("student_profile_complete")
            .select("person_id,full_name,reg_no,department,is_profile_complete")
            .eq("is_profile_complete", value: true)
            .neq("person_id", value: uid.uuidString)
            .order("full_name", ascending: true)
            .execute()
            .value

        return rows
    }
}
extension SupabaseManager {

    struct StudentBasic: Decodable {
        let reg_no: String?
        let department: String?
    }

    func fetchStudentBasic(personId: String) async throws -> (regNo: String?, department: String?) {
        let row: StudentBasic = try await client
            .from("student_profile_complete")
            .select("reg_no, department")
            .eq("person_id", value: personId)
            .single()
            .execute()
            .value

        return (row.reg_no, row.department)
    }
}
import Foundation
import Supabase

extension SupabaseManager {
    
    // Matches your table columns exactly: department, reg_no
    struct StudentProfileMini: Decodable, Sendable {
        let department: String?
        let reg_no: String?
    }
    
    /// Fetch current student's reg_no + department from public.student_profile_complete by person_id
    func fetchStudentMiniProfile(personIdString: String) async throws -> StudentProfileMini {
        let row: StudentProfileMini = try await client
            .from("student_profile_complete")
            .select("department, reg_no")
            .eq("person_id", value: personIdString)
            .single()
            .execute()
            .value
        return row
    }
}
