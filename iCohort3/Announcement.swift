//
//  Announcement.swift
//  iCohort3
//
//  Created by user@51 on 08/11/25.
//

import Foundation

struct Announcement: Equatable {
    let id: UUID
    let title: String
    let body: String
    let tag: String?      // "Event", "Review", etc.
    let createdAt: Date
    let author: String
}
