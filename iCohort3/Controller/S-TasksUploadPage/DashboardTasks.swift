//
//  DashboardTasks.swift
//  iCohort3
//
//  Created by user@51 on 22/02/26.
//

import UIKit

struct DashboardTask {
    let title:           String
    let dueDate:         String
    let assigneeName:    String      // fallback display name (e.g. "Team 3")
    let assigneeImage:   UIImage?
    let attachmentNames: [String]
    var status:          String?
    var remark:          String?

    // ── Supabase identifiers (set by InProgressVC / other status VCs) ─────────
    var taskId:   String?            // tasks.id        (UUID string)
    var teamId:   String?            // tasks.team_id   (UUID string)
    var mentorId: String?            // tasks.mentor_id (UUID string)
}
