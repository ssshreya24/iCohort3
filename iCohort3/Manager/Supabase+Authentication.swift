//
//  SupabaseManager+Authentication.swift
//  iCohort3
//
//  ✅ CLEANED: Removed Team 9 auto-assignment from approval flows
//

import Foundation
import Supabase
import CryptoKit

extension SupabaseManager {
    
    // MARK: - Password Hashing
    
    /// Hash password using SHA-256
    func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Institute Management
    
    struct Institute: Codable, Sendable {
        let id: String
        let name: String
        let domain: String
        let admin_email: String
        let admin_id: String?
        let created_at: String?
    }
    
    /// Register a new institute
    func registerInstitute(
        name: String,
        domain: String,
        adminEmail: String,
        adminId: String
    ) async throws {
        print("🔄 Registering institute:", name)
        
        // Check if institute already exists
        let existing: [Institute] = try await client
            .from("institutes")
            .select()
            .eq("domain", value: domain)
            .limit(1)
            .execute()
            .value
        
        if !existing.isEmpty {
            throw SupabaseError.instituteAlreadyExists
        }
        
        struct InstituteInsert: Encodable {
            let name: String
            let domain: String
            let admin_email: String
            let admin_id: String
        }
        
        let insert = InstituteInsert(
            name: name,
            domain: domain,
            admin_email: adminEmail,
            admin_id: adminId
        )
        
        try await client
            .from("institutes")
            .insert(insert)
            .execute()
        
        print("✅ Institute registered:", name)
    }
    
    /// Get institute by domain
    func getInstitute(byDomain domain: String) async throws -> Institute? {
        let results: [Institute] = try await client
            .from("institutes")
            .select()
            .eq("domain", value: domain)
            .limit(1)
            .execute()
            .value
        
        return results.first
    }
    
    /// Get institute by admin email
    func getInstitute(byAdminEmail email: String) async throws -> Institute? {
        let results: [Institute] = try await client
            .from("institutes")
            .select()
            .eq("admin_email", value: email)
            .limit(1)
            .execute()
            .value
        
        return results.first
    }
    
    // MARK: - Admin Authentication
    
    struct AdminAccount: Codable, Sendable {
        let id: String
        let email: String
        let institute_id: String?
        let is_active: Bool?
        let created_at: String?
    }
    
    /// Register admin account
    func registerAdmin(email: String, password: String, instituteId: String? = nil) async throws {
        print("🔄 Registering admin:", email)
        
        // Check if admin already exists
        let existing: [AdminAccount] = try await client
            .from("admin_accounts")
            .select()
            .eq("email", value: email)
            .limit(1)
            .execute()
            .value
        
        if !existing.isEmpty {
            throw SupabaseError.alreadyRegistered
        }
        
        struct AdminInsert: Encodable {
            let email: String
            let password_hash: String
            let institute_id: String?
        }
        
        let passwordHash = hashPassword(password)
        
        let insert = AdminInsert(
            email: email,
            password_hash: passwordHash,
            institute_id: instituteId
        )
        
        try await client
            .from("admin_accounts")
            .insert(insert)
            .execute()
        
        print("✅ Admin registered:", email)
    }
    
    /// Verify admin credentials
    func verifyAdmin(email: String, password: String) async throws -> Bool {
        print("🔍 Verifying admin:", email)
        
        struct AdminWithHash: Codable {
            let password_hash: String
            let is_active: Bool?
        }
        
        let results: [AdminWithHash] = try await client
            .from("admin_accounts")
            .select("password_hash, is_active")
            .eq("email", value: email)
            .limit(1)
            .execute()
            .value
        
        guard let admin = results.first else {
            print("❌ Admin not found")
            return false
        }
        
        guard admin.is_active != false else {
            print("❌ Admin account is inactive")
            return false
        }
        
        let inputHash = hashPassword(password)
        let verified = inputHash == admin.password_hash
        
        if verified {
            // Update last login
            struct LastLoginUpdate: Encodable {
                let last_login: String
            }
            
            let update = LastLoginUpdate(last_login: ISO8601DateFormatter().string(from: Date()))
            
            try? await client
                .from("admin_accounts")
                .update(update)
                .eq("email", value: email)
                .execute()
            
            print("✅ Admin verified successfully")
        } else {
            print("❌ Invalid password")
        }
        
        return verified
    }
    
    // MARK: - Student Registration
    
    struct StudentRegistration: Codable, Sendable {
        let id: String
        let full_name: String
        let email: String
        let reg_number: String
        let institute_domain: String
        let approval_status: String
        let approved_by: String?
        let approved_at: String?
        let declined_by: String?
        let declined_at: String?
        let created_at: String?
        let updated_at: String?
    }
    
    /// Register a student
    func registerStudent(
        fullName: String,
        email: String,
        regNumber: String,
        password: String,
        instituteDomain: String
    ) async throws -> String {
        print("🔄 Registering student:", email)
        
        // Check if already registered
        let existing: [StudentRegistration] = try await client
            .from("student_registrations")
            .select()
            .eq("email", value: email)
            .limit(1)
            .execute()
            .value
        
        if !existing.isEmpty {
            throw SupabaseError.alreadyRegistered
        }
        
        struct StudentInsert: Encodable {
            let full_name: String
            let email: String
            let reg_number: String
            let password_hash: String
            let institute_domain: String
        }
        
        let passwordHash = hashPassword(password)
        
        let insert = StudentInsert(
            full_name: fullName,
            email: email,
            reg_number: regNumber,
            password_hash: passwordHash,
            institute_domain: instituteDomain
        )
        
        struct RegistrationResponse: Codable {
            let id: String
        }
        
        let response: [RegistrationResponse] = try await client
            .from("student_registrations")
            .insert(insert)
            .select("id")
            .execute()
            .value
        
        guard let registrationId = response.first?.id else {
            throw SupabaseError.insertFailed
        }
        
        print("✅ Student registered with ID:", registrationId)
        return registrationId
    }
    
    /// Get pending students for a domain
    func getPendingStudents(forDomain domain: String) async throws -> [StudentRegistration] {
        print("🔍 Fetching pending students for domain:", domain)
        
        let students: [StudentRegistration] = try await client
            .from("student_registrations")
            .select()
            .eq("institute_domain", value: domain)
            .eq("approval_status", value: "pending")
            .order("created_at", ascending: false)
            .execute()
            .value
        
        print("✅ Found \(students.count) pending students")
        return students
    }
    
    /// Check student approval status
    func checkStudentApproval(email: String) async throws -> String {
        let students: [StudentRegistration] = try await client
            .from("student_registrations")
            .select()
            .eq("email", value: email)
            .limit(1)
            .execute()
            .value
        
        guard let student = students.first else {
            throw SupabaseError.studentNotFound
        }
        
        return student.approval_status
    }
    
    /// Verify student credentials (for login)
    func verifyStudent(email: String, password: String) async throws -> Bool {
        print("🔍 Verifying student:", email)
        
        struct StudentWithHash: Codable {
            let password_hash: String
            let approval_status: String
        }
        
        let results: [StudentWithHash] = try await client
            .from("student_registrations")
            .select("password_hash, approval_status")
            .eq("email", value: email)
            .limit(1)
            .execute()
            .value
        
        guard let student = results.first else {
            print("❌ Student not found")
            return false
        }
        
        guard student.approval_status == "approved" else {
            print("❌ Student not approved yet")
            throw SupabaseError.notApproved
        }
        
        let inputHash = hashPassword(password)
        let verified = inputHash == student.password_hash
        
        print(verified ? "✅ Student verified" : "❌ Invalid password")
        return verified
    }
    
    /// Approve student registration
    func approveStudent(studentId: String, adminEmail: String) async throws {
        print("🔄 Approving student:", studentId)
        
        // Get student data
        let students: [StudentRegistration] = try await client
            .from("student_registrations")
            .select()
            .eq("id", value: studentId)
            .limit(1)
            .execute()
            .value
        
        guard let student = students.first else {
            throw SupabaseError.studentNotFound
        }
        
        // Update approval status
        struct ApprovalUpdate: Encodable {
            let approval_status: String
            let approved_by: String
            let approved_at: String
        }
        
        let update = ApprovalUpdate(
            approval_status: "approved",
            approved_by: adminEmail,
            approved_at: ISO8601DateFormatter().string(from: Date())
        )
        
        try await client
            .from("student_registrations")
            .update(update)
            .eq("id", value: studentId)
            .execute()
        
        // Create person record
        let personId = try await createPersonIfNeeded(
            fullName: student.full_name,
            email: student.email,
            role: "student"
        )
        
        // Create student profile
        let nameParts = student.full_name.components(separatedBy: " ")
        let firstName = nameParts.first ?? student.full_name
        let lastName = nameParts.count > 1 ? nameParts.dropFirst().joined(separator: " ") : ""
        
        struct StudentProfileInsert: Encodable {
            let person_id: String
            let first_name: String
            let last_name: String
            let srm_mail: String
            let reg_no: String?
            let institute_domain: String
            let password_hash: String
            let approved_by: String
            let approved_at: String
            let registration_id: String
            let is_profile_complete: Bool
        }
        
        // Get password hash from registration
        struct RegistrationHash: Codable {
            let password_hash: String
        }
        
        let hashResults: [RegistrationHash] = try await client
            .from("student_registrations")
            .select("password_hash")
            .eq("id", value: studentId)
            .execute()
            .value
        
        let passwordHash = hashResults.first?.password_hash ?? ""
        
        let profileInsert = StudentProfileInsert(
            person_id: personId,
            first_name: firstName,
            last_name: lastName,
            srm_mail: student.email,
            reg_no: student.reg_number.isEmpty ? nil : student.reg_number,
            institute_domain: student.institute_domain,
            password_hash: passwordHash,
            approved_by: adminEmail,
            approved_at: ISO8601DateFormatter().string(from: Date()),
            registration_id: studentId,
            is_profile_complete: !firstName.isEmpty && !lastName.isEmpty
        )
        
        try await client
            .from("student_profiles")
            .upsert(profileInsert, onConflict: "person_id")
            .execute()
        
        // ✅ CLEANED: No Team 9 auto-assignment
        print("✅ Student approved and profile created")
    }
    
    /// Decline student registration
    func declineStudent(studentId: String, adminEmail: String) async throws {
        print("🔄 Declining student:", studentId)
        
        struct DeclineUpdate: Encodable {
            let approval_status: String
            let declined_by: String
            let declined_at: String
        }
        
        let update = DeclineUpdate(
            approval_status: "declined",
            declined_by: adminEmail,
            declined_at: ISO8601DateFormatter().string(from: Date())
        )
        
        try await client
            .from("student_registrations")
            .update(update)
            .eq("id", value: studentId)
            .execute()
        
        print("✅ Student declined")
    }
    
    // MARK: - Mentor Registration
    
    struct MentorRegistration: Codable, Sendable {
        let id: String
        let full_name: String
        let email: String
        let employee_id: String
        let designation: String
        let department: String
        let institute_name: String
        let institute_domain: String?
        let approval_status: String
        let approved_by: String?
        let approved_at: String?
        let declined_by: String?
        let declined_at: String?
        let created_at: String?
        let updated_at: String?
    }
    
    func verifyStudentFromProfiles(email: String, password: String) async throws -> Bool {
        struct ProfileWithHash: Codable {
            let password_hash: String
            let is_profile_complete: Bool?
        }
        let results: [ProfileWithHash] = try await client
            .from("student_profiles")
            .select("password_hash, is_profile_complete")
            .eq("srm_mail", value: email)
            .limit(1)
            .execute()
            .value
        guard let profile = results.first else {
            throw SupabaseError.studentNotFound
        }
        return hashPassword(password) == profile.password_hash
    }
    
    /// Register a mentor
    func registerMentor(
        fullName: String,
        email: String,
        employeeId: String,
        designation: String,
        department: String,
        instituteName: String,
        password: String
    ) async throws -> String {
        print("🔄 Registering mentor:", email)
        
        // Check if already registered
        let existing: [MentorRegistration] = try await client
            .from("mentor_registrations")
            .select()
            .eq("email", value: email)
            .limit(1)
            .execute()
            .value
        
        if !existing.isEmpty {
            throw SupabaseError.alreadyRegistered
        }
        
        struct MentorInsert: Encodable {
            let full_name: String
            let email: String
            let employee_id: String
            let designation: String
            let department: String
            let password_hash: String
            let institute_name: String
        }
        
        let passwordHash = hashPassword(password)
        
        let insert = MentorInsert(
            full_name: fullName,
            email: email,
            employee_id: employeeId,
            designation: designation,
            department: department,
            password_hash: passwordHash,
            institute_name: instituteName
        )
        
        struct RegistrationResponse: Codable {
            let id: String
        }
        
        let response: [RegistrationResponse] = try await client
            .from("mentor_registrations")
            .insert(insert)
            .select("id")
            .execute()
            .value
        
        guard let registrationId = response.first?.id else {
            throw SupabaseError.insertFailed
        }
        
        print("✅ Mentor registered with ID:", registrationId)
        return registrationId
    }
    
    /// Get pending mentors for an institute
    func getPendingMentors(forInstituteName name: String) async throws -> [MentorRegistration] {
        print("🔍 Fetching pending mentors for institute:", name)
        
        let mentors: [MentorRegistration] = try await client
            .from("mentor_registrations")
            .select()
            .eq("institute_name", value: name)
            .eq("approval_status", value: "pending")
            .order("created_at", ascending: false)
            .execute()
            .value
        
        print("✅ Found \(mentors.count) pending mentors")
        return mentors
    }
    
    /// Check mentor approval status
    func checkMentorApproval(email: String) async throws -> String {
        let mentors: [MentorRegistration] = try await client
            .from("mentor_registrations")
            .select()
            .eq("email", value: email)
            .limit(1)
            .execute()
            .value
        
        guard let mentor = mentors.first else {
            throw SupabaseError.mentorNotFound
        }
        
        return mentor.approval_status
    }
    
    /// Verify mentor credentials (for login)
    func verifyMentor(email: String, password: String) async throws -> Bool {
        print("🔍 Verifying mentor:", email)
        
        struct MentorWithHash: Codable {
            let password_hash: String
            let approval_status: String
        }
        
        let results: [MentorWithHash] = try await client
            .from("mentor_registrations")
            .select("password_hash, approval_status")
            .eq("email", value: email)
            .limit(1)
            .execute()
            .value
        
        guard let mentor = results.first else {
            print("❌ Mentor not found")
            return false
        }
        
        guard mentor.approval_status == "approved" else {
            print("❌ Mentor not approved yet")
            throw SupabaseError.notApproved
        }
        
        let inputHash = hashPassword(password)
        let verified = inputHash == mentor.password_hash
        
        print(verified ? "✅ Mentor verified" : "❌ Invalid password")
        return verified
    }
    
    /// Approve mentor registration
    func approveMentor(mentorId: String, adminEmail: String) async throws {
        print("🔄 Approving mentor:", mentorId)
        
        // Get mentor data
        let mentors: [MentorRegistration] = try await client
            .from("mentor_registrations")
            .select()
            .eq("id", value: mentorId)
            .limit(1)
            .execute()
            .value
        
        guard let mentor = mentors.first else {
            throw SupabaseError.mentorNotFound
        }
        
        // Update approval status
        struct ApprovalUpdate: Encodable {
            let approval_status: String
            let approved_by: String
            let approved_at: String
        }
        
        let update = ApprovalUpdate(
            approval_status: "approved",
            approved_by: adminEmail,
            approved_at: ISO8601DateFormatter().string(from: Date())
        )
        
        try await client
            .from("mentor_registrations")
            .update(update)
            .eq("id", value: mentorId)
            .execute()
        
        // Create person record
        let personId = try await createPersonIfNeeded(
            fullName: mentor.full_name,
            email: mentor.email,
            role: "mentor"
        )
        
        // Create mentor profile
        let nameParts = mentor.full_name.components(separatedBy: " ")
        let firstName = nameParts.first ?? mentor.full_name
        let lastName = nameParts.count > 1 ? nameParts.dropFirst().joined(separator: " ") : ""
        
        struct MentorProfileInsert: Encodable {
            let person_id: String
            let first_name: String
            let last_name: String
            let email: String
            let employee_id: String?
            let designation: String?
            let department: String?
            let institute_name: String
            let password_hash: String
            let approved_by: String
            let approved_at: String
            let registration_id: String
            let is_profile_complete: Bool
        }
        
        // Get password hash
        struct RegistrationHash: Codable {
            let password_hash: String
        }
        
        let hashResults: [RegistrationHash] = try await client
            .from("mentor_registrations")
            .select("password_hash")
            .eq("id", value: mentorId)
            .execute()
            .value
        
        let passwordHash = hashResults.first?.password_hash ?? ""
        
        let profileInsert = MentorProfileInsert(
            person_id: personId,
            first_name: firstName,
            last_name: lastName,
            email: mentor.email,
            employee_id: mentor.employee_id.isEmpty ? nil : mentor.employee_id,
            designation: mentor.designation.isEmpty ? nil : mentor.designation,
            department: mentor.department.isEmpty ? nil : mentor.department,
            institute_name: mentor.institute_name,
            password_hash: passwordHash,
            approved_by: adminEmail,
            approved_at: ISO8601DateFormatter().string(from: Date()),
            registration_id: mentorId,
            is_profile_complete: !firstName.isEmpty && !lastName.isEmpty
        )
        
        try await client
            .from("mentor_profiles")
            .upsert(profileInsert, onConflict: "person_id")
            .execute()
        
        print("✅ Mentor approved and profile created")
    }
    
    /// Decline mentor registration
    func declineMentor(mentorId: String, adminEmail: String) async throws {
        print("🔄 Declining mentor:", mentorId)
        
        struct DeclineUpdate: Encodable {
            let approval_status: String
            let declined_by: String
            let declined_at: String
        }
        
        let update = DeclineUpdate(
            approval_status: "declined",
            declined_by: adminEmail,
            declined_at: ISO8601DateFormatter().string(from: Date())
        )
        
        try await client
            .from("mentor_registrations")
            .update(update)
            .eq("id", value: mentorId)
            .execute()
        
        print("✅ Mentor declined")
    }
    
    // MARK: - Helper Functions
    
    /// Create person record if it doesn't exist
    private func createPersonIfNeeded(fullName: String, email: String, role: String) async throws -> String {
        print("🔍 Checking if person exists for:", email)
        
        // Check if person already exists
        if role == "student" {
            if let personId = try await fetchStudentId(srmMail: email) {
                print("✅ Found existing person:", personId)
                return personId
            }
        } else if role == "mentor" {
            if let personId = try await fetchMentorId(email: email) {
                print("✅ Found existing person:", personId)
                return personId
            }
        }
        
        // Create new person
        print("📝 Creating new person...")
        
        struct PersonInsert: Encodable {
            let full_name: String
            let role: String
        }
        
        struct PersonResponse: Codable {
            let id: String
        }
        
        let insert = PersonInsert(full_name: fullName, role: role)
        
        let response: [PersonResponse] = try await client
            .from("people")
            .insert(insert)
            .select("id")
            .execute()
            .value
        
        guard let personId = response.first?.id else {
            throw SupabaseError.insertFailed
        }
        
        print("✅ Created person:", personId)
        return personId
    }
    
    // MARK: - Count Functions
    
    /// Count approved students for a domain
    func countApprovedStudents(forDomain domain: String) async throws -> Int {
        print("🔍 Counting approved students for domain:", domain)
        
        let students: [StudentRegistration] = try await client
            .from("student_registrations")
            .select()
            .eq("institute_domain", value: domain)
            .eq("approval_status", value: "approved")
            .execute()
            .value
        
        let count = students.count
        print("✅ Found \(count) approved students")
        return count
    }

    /// Count approved mentors for an institute
    func countApprovedMentors(forInstituteName name: String) async throws -> Int {
        print("🔍 Counting approved mentors for institute:", name)
        
        let mentors: [MentorRegistration] = try await client
            .from("mentor_registrations")
            .select()
            .eq("institute_name", value: name)
            .eq("approval_status", value: "approved")
            .execute()
            .value
        
        let count = mentors.count
        print("✅ Found \(count) approved mentors")
        return count
    }
    
    // MARK: - Enhanced Mentor Registration with Domain
    
    func registerMentorWithDomain(
        fullName: String,
        email: String,
        employeeId: String,
        designation: String,
        department: String,
        instituteName: String,
        instituteDomain: String,
        password: String
    ) async throws -> String {
        print("🔄 Registering mentor with domain routing:")
        print("   Email:", email)
        print("   Institute:", instituteName)
        print("   Domain:", instituteDomain)
        
        let existing: [MentorRegistration] = try await client
            .from("mentor_registrations")
            .select()
            .eq("email", value: email)
            .limit(1)
            .execute()
            .value
        
        if !existing.isEmpty {
            throw SupabaseError.alreadyRegistered
        }
        
        struct MentorInsertWithDomain: Encodable {
            let full_name: String
            let email: String
            let employee_id: String
            let designation: String
            let department: String
            let password_hash: String
            let institute_name: String
            let institute_domain: String
        }
        
        let passwordHash = hashPassword(password)
        
        let insert = MentorInsertWithDomain(
            full_name: fullName,
            email: email,
            employee_id: employeeId,
            designation: designation,
            department: department,
            password_hash: passwordHash,
            institute_name: instituteName,
            institute_domain: instituteDomain
        )
        
        struct RegistrationResponse: Codable {
            let id: String
        }
        
        let response: [RegistrationResponse] = try await client
            .from("mentor_registrations")
            .insert(insert)
            .select("id")
            .execute()
            .value
        
        guard let registrationId = response.first?.id else {
            throw SupabaseError.insertFailed
        }
        
        print("✅ Mentor registered with domain routing. ID:", registrationId)
        return registrationId
    }
    
    /// Fetch all registered institutes for mentor selection
    func getAllInstitutes() async throws -> [Institute] {
        let institutes: [Institute] = try await client
            .from("institutes")
            .select()
            .order("name")
            .execute()
            .value
        
        return institutes
    }
    
    /// Get pending mentors for admin's institute BY DOMAIN
    func getPendingMentorsByDomain(instituteDomain: String) async throws -> [MentorRegistration] {
        print("🔍 Fetching pending mentors for domain:", instituteDomain)
        
        let mentors: [MentorRegistration] = try await client
            .from("mentor_registrations")
            .select()
            .eq("institute_domain", value: instituteDomain)
            .eq("approval_status", value: "pending")
            .order("created_at", ascending: false)
            .execute()
            .value
        
        print("✅ Found \(mentors.count) pending mentors for domain:", instituteDomain)
        return mentors
    }
    
    /// Count approved mentors by domain
    func countApprovedMentorsByDomain(instituteDomain: String) async throws -> Int {
        print("🔍 Counting approved mentors for domain:", instituteDomain)
        
        let mentors: [MentorRegistration] = try await client
            .from("mentor_registrations")
            .select()
            .eq("institute_domain", value: instituteDomain)
            .eq("approval_status", value: "approved")
            .execute()
            .value
        
        let count = mentors.count
        print("✅ Found \(count) approved mentors for domain:", instituteDomain)
        return count
    }
}

// MARK: - Custom Errors

enum SupabaseError: Error, LocalizedError {
    case studentNotFound
    case mentorNotFound
    case adminNotFound
    case instituteNotFound
    case alreadyRegistered
    case instituteAlreadyExists
    case invalidData
    case insertFailed
    case notApproved
    
    var errorDescription: String? {
        switch self {
        case .studentNotFound:
            return "Student registration not found"
        case .mentorNotFound:
            return "Mentor registration not found"
        case .adminNotFound:
            return "Admin account not found"
        case .instituteNotFound:
            return "Institute not found"
        case .alreadyRegistered:
            return "This email is already registered"
        case .instituteAlreadyExists:
            return "Institute with this domain already exists"
        case .invalidData:
            return "Invalid data format"
        case .insertFailed:
            return "Failed to insert record"
        case .notApproved:
            return "Your registration is not yet approved. Please wait for admin approval."
        }
    }
}
