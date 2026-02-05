//
//  SupabseModels.swift
//  iCohort3
//
//  Created by admin100 on 01/02/26.
//

import Foundation

// MARK: - Student Profile (student_profile_complete)

struct StudentProfileCompleteRow: Decodable {
    let authId: String
    let name: String
    let regNo: String
    let department: String

    enum CodingKeys: String, CodingKey {
        case authId = "auth_id"
        case name
        case regNo = "reg_no"
        case department
    }
}

// MARK: - Team Member Request (team_member_requests)

struct TeamMemberRequestRow: Decodable {
    let id: String
    let fromStudentId: String
    let fromStudentName: String
    let toStudentId: String
    let toStudentName: String
    let status: String
    let createdAt: String

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

// MARK: - Insert Payload

struct InsertTeamMemberRequestRow: Encodable {
    let fromStudentId: String
    let fromStudentName: String
    let toStudentId: String
    let toStudentName: String

    enum CodingKeys: String, CodingKey {
        case fromStudentId = "from_student_id"
        case fromStudentName = "from_student_name"
        case toStudentId = "to_student_id"
        case toStudentName = "to_student_name"
    }
}
