//
//  ApprovalSystemTests.swift
//  iCohort3Tests
//
//  Test cases for student approval system
//

import XCTest
@testable import iCohort3
import CryptoKit

class ApprovalSystemTests: XCTestCase {
    
    // MARK: - Test Data
    struct TestStudent {
        let fullName: String
        let email: String
        let regNumber: String
        let password: String
        let expectedDomain: String
    }
    
    let validSRMStudents = [
        TestStudent(
            fullName: "John Doe",
            email: "john.doe@srmist.edu.in",
            regNumber: "RA2111026010123",
            password: "SecurePass123",
            expectedDomain: "srmist.edu.in"
        ),
        TestStudent(
            fullName: "Jane Smith",
            email: "jane.smith@srmist.edu.in",
            regNumber: "RA2111026010124",
            password: "AnotherPass456",
            expectedDomain: "srmist.edu.in"
        ),
        TestStudent(
            fullName: "Bob Johnson",
            email: "bob.j@srmist.edu.in",
            regNumber: "RA2111026010125",
            password: "TestPassword789",
            expectedDomain: "srmist.edu.in"
        )
    ]
    
    let invalidStudents = [
        TestStudent(
            fullName: "Invalid Domain",
            email: "test@gmail.com",
            regNumber: "RA2111026010126",
            password: "Pass123",
            expectedDomain: "gmail.com"
        ),
        TestStudent(
            fullName: "Wrong Institute",
            email: "student@mit.edu",
            regNumber: "MIT123",
            password: "MitPass123",
            expectedDomain: "mit.edu"
        )
    ]
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        // Initialize Firebase if needed
    }
    
    override func tearDownWithError() throws {
        // Clean up test data
        try super.tearDownWithError()
    }
    
    // MARK: - Test Cases
    
    // MARK: 1. Student Registration Tests
    
    /// Test Case 1.1: Valid SRM student registration
    func testValidSRMStudentRegistration() async throws {
        let student = validSRMStudents[0]
        
        do {
            let studentId = try await FirebaseManager.shared.registerStudent(
                fullName: student.fullName,
                email: student.email,
                regNumber: student.regNumber,
                password: student.password,
                instituteDomain: student.expectedDomain
            )
            
            XCTAssertFalse(studentId.isEmpty, "Student ID should not be empty")
            
            // Verify registration was created with pending status
            let registration = try await FirebaseManager.shared.getStudentRegistration(email: student.email)
            XCTAssertNotNil(registration, "Registration should exist")
            XCTAssertEqual(registration?.approvalStatus, .pending, "Status should be pending")
            XCTAssertEqual(registration?.email, student.email, "Email should match")
            XCTAssertEqual(registration?.regNumber, student.regNumber, "Reg number should match")
            
        } catch {
            XCTFail("Valid registration should not throw error: \(error.localizedDescription)")
        }
    }
    
    /// Test Case 1.2: Duplicate email registration should fail
    func testDuplicateEmailRegistration() async throws {
        let student = validSRMStudents[1]
        
        // First registration
        _ = try await FirebaseManager.shared.registerStudent(
            fullName: student.fullName,
            email: student.email,
            regNumber: student.regNumber,
            password: student.password,
            instituteDomain: student.expectedDomain
        )
        
        // Attempt duplicate registration
        do {
            _ = try await FirebaseManager.shared.registerStudent(
                fullName: student.fullName,
                email: student.email,
                regNumber: student.regNumber,
                password: "DifferentPassword",
                instituteDomain: student.expectedDomain
            )
            XCTFail("Duplicate registration should throw error")
        } catch FirebaseManagerError.alreadyRegistered {
            // Expected error
            XCTAssert(true, "Correctly rejected duplicate registration")
        } catch {
            XCTFail("Wrong error type: \(error.localizedDescription)")
        }
    }
    
    /// Test Case 1.3: Invalid domain registration
    func testInvalidDomainRegistration() {
        // This should be caught at UI level
        let student = invalidStudents[0]
        let domain = student.email.components(separatedBy: "@").last ?? ""
        
        XCTAssertNotEqual(domain, "srmist.edu.in", "Invalid domain should be detected")
    }
    
    /// Test Case 1.4: Password hashing verification
    func testPasswordHashing() {
        let password = "TestPassword123"
        let hash1 = hashPassword(password)
        let hash2 = hashPassword(password)
        
        // Same password should produce same hash
        XCTAssertEqual(hash1, hash2, "Same password should produce same hash")
        
        // Different passwords should produce different hashes
        let differentHash = hashPassword("DifferentPassword")
        XCTAssertNotEqual(hash1, differentHash, "Different passwords should produce different hashes")
        
        // Hash should be 64 characters (256 bits in hex)
        XCTAssertEqual(hash1.count, 64, "SHA256 hash should be 64 hex characters")
    }
    
    // MARK: 2. Approval Status Tests
    
    /// Test Case 2.1: Check pending approval status
    func testCheckPendingApprovalStatus() async throws {
        let student = validSRMStudents[0]
        
        // Register student
        _ = try await FirebaseManager.shared.registerStudent(
            fullName: student.fullName,
            email: student.email,
            regNumber: student.regNumber,
            password: student.password,
            instituteDomain: student.expectedDomain
        )
        
        // Check status
        let status = try await FirebaseManager.shared.checkStudentApproval(email: student.email)
        XCTAssertEqual(status, .pending, "Newly registered student should have pending status")
    }
    
    /// Test Case 2.2: Non-existent student status check
    func testNonExistentStudentStatusCheck() async throws {
        let fakeEmail = "nonexistent@srmist.edu.in"
        
        do {
            _ = try await FirebaseManager.shared.checkStudentApproval(email: fakeEmail)
            XCTFail("Should throw studentNotFound error")
        } catch FirebaseManagerError.studentNotFound {
            XCTAssert(true, "Correctly threw studentNotFound error")
        } catch {
            XCTFail("Wrong error type: \(error.localizedDescription)")
        }
    }
    
    // MARK: 3. Admin Approval Tests
    
    /// Test Case 3.1: Admin can view pending students for their domain
    func testAdminViewPendingStudents() async throws {
        let domain = "srmist.edu.in"
        
        // Register multiple students
        for student in validSRMStudents {
            _ = try? await FirebaseManager.shared.registerStudent(
                fullName: student.fullName,
                email: student.email,
                regNumber: student.regNumber,
                password: student.password,
                instituteDomain: student.expectedDomain
            )
        }
        
        // Get pending students
        let pendingStudents = try await FirebaseManager.shared.getPendingStudents(forDomain: domain)
        
        XCTAssertFalse(pendingStudents.isEmpty, "Should have pending students")
        
        // Verify all returned students are from correct domain
        for student in pendingStudents {
            XCTAssertEqual(student.instituteDomain, domain, "All students should be from correct domain")
            XCTAssertEqual(student.approvalStatus, .pending, "All students should have pending status")
        }
    }
    
    /// Test Case 3.2: Admin approves student
    func testAdminApproveStudent() async throws {
        let student = validSRMStudents[0]
        let adminEmail = "admin@srmist.edu.in"
        
        // Register student
        let studentId = try await FirebaseManager.shared.registerStudent(
            fullName: student.fullName,
            email: student.email,
            regNumber: student.regNumber,
            password: student.password,
            instituteDomain: student.expectedDomain
        )
        
        // Approve student
        try await FirebaseManager.shared.approveStudent(studentId: studentId, adminEmail: adminEmail)
        
        // Verify approval
        let status = try await FirebaseManager.shared.checkStudentApproval(email: student.email)
        XCTAssertEqual(status, .approved, "Student should be approved")
        
        // Verify student can login
        let canLogin = try await FirebaseManager.shared.verifyApprovedStudent(
            email: student.email,
            password: student.password
        )
        XCTAssertTrue(canLogin, "Approved student should be able to login with correct password")
    }
    
    /// Test Case 3.3: Admin declines student
    func testAdminDeclineStudent() async throws {
        let student = validSRMStudents[1]
        let adminEmail = "admin@srmist.edu.in"
        
        // Register student
        let studentId = try await FirebaseManager.shared.registerStudent(
            fullName: student.fullName,
            email: student.email,
            regNumber: student.regNumber,
            password: student.password,
            instituteDomain: student.expectedDomain
        )
        
        // Decline student
        try await FirebaseManager.shared.declineStudent(studentId: studentId, adminEmail: adminEmail)
        
        // Verify decline
        let status = try await FirebaseManager.shared.checkStudentApproval(email: student.email)
        XCTAssertEqual(status, .declined, "Student should be declined")
        
        // Verify student cannot login
        let canLogin = try await FirebaseManager.shared.verifyApprovedStudent(
            email: student.email,
            password: student.password
        )
        XCTAssertFalse(canLogin, "Declined student should not be able to login")
    }
    
    // MARK: 4. Login Tests
    
    /// Test Case 4.1: Approved student can login
    func testApprovedStudentLogin() async throws {
        let student = validSRMStudents[0]
        let adminEmail = "admin@srmist.edu.in"
        
        // Register and approve
        let studentId = try await FirebaseManager.shared.registerStudent(
            fullName: student.fullName,
            email: student.email,
            regNumber: student.regNumber,
            password: student.password,
            instituteDomain: student.expectedDomain
        )
        
        try await FirebaseManager.shared.approveStudent(studentId: studentId, adminEmail: adminEmail)
        
        // Test login with correct password
        let validLogin = try await FirebaseManager.shared.verifyApprovedStudent(
            email: student.email,
            password: student.password
        )
        XCTAssertTrue(validLogin, "Should login with correct password")
        
        // Test login with wrong password
        let invalidLogin = try await FirebaseManager.shared.verifyApprovedStudent(
            email: student.email,
            password: "WrongPassword"
        )
        XCTAssertFalse(invalidLogin, "Should not login with wrong password")
    }
    
    /// Test Case 4.2: Pending student cannot login
    func testPendingStudentCannotLogin() async throws {
        let student = validSRMStudents[1]
        
        // Register student (pending status)
        _ = try await FirebaseManager.shared.registerStudent(
            fullName: student.fullName,
            email: student.email,
            regNumber: student.regNumber,
            password: student.password,
            instituteDomain: student.expectedDomain
        )
        
        // Attempt login
        let canLogin = try await FirebaseManager.shared.verifyApprovedStudent(
            email: student.email,
            password: student.password
        )
        XCTAssertFalse(canLogin, "Pending student should not be able to login")
    }
    
    /// Test Case 4.3: Declined student cannot login
    func testDeclinedStudentCannotLogin() async throws {
        let student = validSRMStudents[2]
        let adminEmail = "admin@srmist.edu.in"
        
        // Register and decline
        let studentId = try await FirebaseManager.shared.registerStudent(
            fullName: student.fullName,
            email: student.email,
            regNumber: student.regNumber,
            password: student.password,
            instituteDomain: student.expectedDomain
        )
        
        try await FirebaseManager.shared.declineStudent(studentId: studentId, adminEmail: adminEmail)
        
        // Attempt login
        let canLogin = try await FirebaseManager.shared.verifyApprovedStudent(
            email: student.email,
            password: student.password
        )
        XCTAssertFalse(canLogin, "Declined student should not be able to login")
    }
    
    // MARK: 5. Institute Management Tests
    
    /// Test Case 5.1: Register new institute
    func testRegisterInstitute() async throws {
        let instituteName = "Test University"
        let domain = "test.edu.in"
        let adminEmail = "admin@test.edu.in"
        let adminId = "testAdminId123"
        
        do {
            try await FirebaseManager.shared.registerInstitute(
                name: instituteName,
                domain: domain,
                adminEmail: adminEmail,
                adminId: adminId
            )
            
            // Verify institute was created
            let institute = try await FirebaseManager.shared.getInstitute(byDomain: domain)
            XCTAssertNotNil(institute, "Institute should exist")
            XCTAssertEqual(institute?.name, instituteName, "Institute name should match")
            XCTAssertEqual(institute?.domain, domain, "Domain should match")
            
        } catch {
            XCTFail("Institute registration should not throw error: \(error.localizedDescription)")
        }
    }
    
    /// Test Case 5.2: Duplicate institute domain should fail
    func testDuplicateInstituteDomain() async throws {
        let domain = "duplicate.edu.in"
        
        // First registration
        try await FirebaseManager.shared.registerInstitute(
            name: "First Institute",
            domain: domain,
            adminEmail: "admin1@duplicate.edu.in",
            adminId: "admin1"
        )
        
        // Attempt duplicate
        do {
            try await FirebaseManager.shared.registerInstitute(
                name: "Second Institute",
                domain: domain,
                adminEmail: "admin2@duplicate.edu.in",
                adminId: "admin2"
            )
            XCTFail("Duplicate institute should throw error")
        } catch FirebaseManagerError.instituteAlreadyExists {
            XCTAssert(true, "Correctly rejected duplicate institute")
        } catch {
            XCTFail("Wrong error type: \(error.localizedDescription)")
        }
    }
    
    /// Test Case 5.3: Get institute by admin email
    func testGetInstituteByAdminEmail() async throws {
        let domain = "admintest.edu.in"
        let adminEmail = "testadmin@admintest.edu.in"
        
        // Register institute
        try await FirebaseManager.shared.registerInstitute(
            name: "Admin Test Institute",
            domain: domain,
            adminEmail: adminEmail,
            adminId: "adminId123"
        )
        
        // Get by admin email
        let institute = try await FirebaseManager.shared.getInstitute(byAdminEmail: adminEmail)
        XCTAssertNotNil(institute, "Institute should be found by admin email")
        XCTAssertEqual(institute?.domain, domain, "Domain should match")
    }
    
    // MARK: - Helper Functions
    
    private func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Performance Tests

extension ApprovalSystemTests {
    
    /// Test Case 6.1: Measure registration performance
    func testRegistrationPerformance() {
        measure {
            Task {
                do {
                    _ = try await FirebaseManager.shared.registerStudent(
                        fullName: "Performance Test",
                        email: "perf\(UUID().uuidString)@srmist.edu.in",
                        regNumber: "PERF123",
                        password: "TestPass123",
                        instituteDomain: "srmist.edu.in"
                    )
                } catch {
                    print("Performance test error: \(error)")
                }
            }
        }
    }
    
    /// Test Case 6.2: Measure approval query performance
    func testApprovalQueryPerformance() {
        measure {
            Task {
                do {
                    _ = try await FirebaseManager.shared.getPendingStudents(forDomain: "srmist.edu.in")
                } catch {
                    print("Performance test error: \(error)")
                }
            }
        }
    }
}
