//
//  FirebaseManager.swift
//  iCohort3
//
//  Firebase Firestore manager for student approval system
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import CryptoKit

class FirebaseManager {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Collections
    private var studentRegistrationsRef: CollectionReference {
        db.collection("student_registrations")
    }
    
    private var institutesRef: CollectionReference {
        db.collection("institutes")
    }
    
    private var approvedStudentsRef: CollectionReference {
        db.collection("approved_students")
    }
    
    // MARK: - Student Registration
    
    /// Register a new student with pending approval status
    func registerStudent(
        fullName: String,
        email: String,
        regNumber: String,
        password: String,
        instituteDomain: String
    ) async throws -> String {
        
        // Check if already registered
        let existingQuery = studentRegistrationsRef
            .whereField("email", isEqualTo: email)
            .limit(to: 1)
        
        let existingSnapshot = try await existingQuery.getDocuments()
        if !existingSnapshot.documents.isEmpty {
            throw FirebaseManagerError.alreadyRegistered
        }
        
        // Hash password
        let passwordHash = hashPassword(password)
        
        let data: [String: Any] = [
            "fullName": fullName,
            "email": email,
            "regNumber": regNumber,
            "passwordHash": passwordHash,
            "instituteDomain": instituteDomain,
            "approvalStatus": "pending",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        let docRef = try await studentRegistrationsRef.addDocument(data: data)
        print("✅ Student registered with ID:", docRef.documentID)
        
        return docRef.documentID
    }
    
    /// Check student approval status
    func checkStudentApproval(email: String) async throws -> ApprovalStatus {
        let query = studentRegistrationsRef
            .whereField("email", isEqualTo: email)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        
        guard let document = snapshot.documents.first else {
            throw FirebaseManagerError.studentNotFound
        }
        
        let status = document.data()["approvalStatus"] as? String ?? "pending"
        return ApprovalStatus(rawValue: status) ?? .pending
    }
    
    /// Get student registration by email
    func getStudentRegistration(email: String) async throws -> StudentRegistration? {
        let query = studentRegistrationsRef
            .whereField("email", isEqualTo: email)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        
        guard let document = snapshot.documents.first else {
            return nil
        }
        
        return try parseStudentRegistration(document: document)
    }
    
    // MARK: - Admin Operations
    
    /// Get all pending students for a specific domain
    func getPendingStudents(forDomain domain: String) async throws -> [StudentRegistration] {
        let query = studentRegistrationsRef
            .whereField("instituteDomain", isEqualTo: domain)
            .whereField("approvalStatus", isEqualTo: "pending")
            .order(by: "createdAt", descending: true)
        
        let snapshot = try await query.getDocuments()
        
        return try snapshot.documents.compactMap { doc in
            try parseStudentRegistration(document: doc)
        }
    }
    
    /// Approve a student registration
    func approveStudent(studentId: String, adminEmail: String) async throws {
        let docRef = studentRegistrationsRef.document(studentId)
        
        // Get student data
        let document = try await docRef.getDocument()
        guard document.exists else {
            throw FirebaseManagerError.studentNotFound
        }
        
        let data = document.data()
        guard let email = data?["email"] as? String,
              let passwordHash = data?["passwordHash"] as? String,
              let fullName = data?["fullName"] as? String,
              let regNumber = data?["regNumber"] as? String else {
            throw FirebaseManagerError.invalidData
        }
        
        // Update approval status
        try await docRef.updateData([
            "approvalStatus": "approved",
            "approvedBy": adminEmail,
            "approvedAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ])
        
        // Add to approved students collection (for login verification)
        let approvedData: [String: Any] = [
            "email": email,
            "passwordHash": passwordHash,
            "fullName": fullName,
            "regNumber": regNumber,
            "approvedAt": FieldValue.serverTimestamp(),
            "approvedBy": adminEmail
        ]
        
        try await approvedStudentsRef.document(email).setData(approvedData)
        
        print("✅ Student approved:", email)
    }
    
    /// Decline a student registration
    func declineStudent(studentId: String, adminEmail: String) async throws {
        let docRef = studentRegistrationsRef.document(studentId)
        
        try await docRef.updateData([
            "approvalStatus": "declined",
            "declinedBy": adminEmail,
            "declinedAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ])
        
        print("✅ Student declined:", studentId)
    }
    
    /// Verify if student is approved and can login
    func verifyApprovedStudent(email: String, password: String) async throws -> Bool {
        let docRef = approvedStudentsRef.document(email)
        let document = try await docRef.getDocument()
        
        guard document.exists,
              let data = document.data(),
              let storedHash = data["passwordHash"] as? String else {
            return false
        }
        
        let inputHash = hashPassword(password)
        return inputHash == storedHash
    }
    
    // MARK: - Institute Management
    
    /// Register a new institute
    func registerInstitute(
        name: String,
        domain: String,
        adminEmail: String,
        adminId: String
    ) async throws {
        
        // Check if institute already exists
        let query = institutesRef
            .whereField("domain", isEqualTo: domain)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        if !snapshot.documents.isEmpty {
            throw FirebaseManagerError.instituteAlreadyExists
        }
        
        let data: [String: Any] = [
            "name": name,
            "domain": domain,
            "adminEmail": adminEmail,
            "adminId": adminId,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        try await institutesRef.document(domain).setData(data)
        print("✅ Institute registered:", name)
    }
    
    /// Get institute by domain
    func getInstitute(byDomain domain: String) async throws -> Institute? {
        let document = try await institutesRef.document(domain).getDocument()
        
        guard document.exists, let data = document.data() else {
            return nil
        }
        
        return Institute(
            name: data["name"] as? String ?? "",
            domain: data["domain"] as? String ?? "",
            adminEmail: data["adminEmail"] as? String ?? "",
            adminId: data["adminId"] as? String ?? ""
        )
    }
    
    /// Get institute by admin email
    func getInstitute(byAdminEmail email: String) async throws -> Institute? {
        let query = institutesRef
            .whereField("adminEmail", isEqualTo: email)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        
        guard let document = snapshot.documents.first,
              let data = document.data() as? [String: Any] else {
            return nil
        }
        
        return Institute(
            name: data["name"] as? String ?? "",
            domain: data["domain"] as? String ?? "",
            adminEmail: data["adminEmail"] as? String ?? "",
            adminId: data["adminId"] as? String ?? ""
        )
    }
    
    // MARK: - Helper Methods
    
    private func parseStudentRegistration(document: DocumentSnapshot) throws -> StudentRegistration {
        guard let data = document.data() else {
            throw FirebaseManagerError.invalidData
        }
        
        let statusString = data["approvalStatus"] as? String ?? "pending"
        let status = ApprovalStatus(rawValue: statusString) ?? .pending
        
        return StudentRegistration(
            id: document.documentID,
            fullName: data["fullName"] as? String ?? "",
            email: data["email"] as? String ?? "",
            regNumber: data["regNumber"] as? String ?? "",
            instituteDomain: data["instituteDomain"] as? String ?? "",
            approvalStatus: status,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue(),
            approvedBy: data["approvedBy"] as? String,
            approvedAt: (data["approvedAt"] as? Timestamp)?.dateValue()
        )
    }
    
    private func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Models

struct StudentRegistration {
    let id: String
    let fullName: String
    let email: String
    let regNumber: String
    let instituteDomain: String
    let approvalStatus: ApprovalStatus
    let createdAt: Date?
    let approvedBy: String?
    let approvedAt: Date?
}

struct Institute {
    let name: String
    let domain: String
    let adminEmail: String
    let adminId: String
}

enum ApprovalStatus: String {
    case pending = "pending"
    case approved = "approved"
    case declined = "declined"
}

enum FirebaseManagerError: Error, LocalizedError {
    case studentNotFound
    case instituteNotFound
    case invalidDomain
    case alreadyRegistered
    case instituteAlreadyExists
    case invalidData
    case notApproved
    
    var errorDescription: String? {
        switch self {
        case .studentNotFound:
            return "Student registration not found"
        case .instituteNotFound:
            return "Institute not found"
        case .invalidDomain:
            return "Invalid email domain for this institute"
        case .alreadyRegistered:
            return "This email is already registered"
        case .instituteAlreadyExists:
            return "Institute with this domain already exists"
        case .invalidData:
            return "Invalid data format"
        case .notApproved:
            return "Your registration is not yet approved"
        }
    }
}
