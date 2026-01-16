//
//  TaskModel.swift
//  iCohort3
//
//  Created by user@51 on 14/01/26.
//

import UIKit

enum TaskCategory: String {
    case assigned = "assigned"
    case review = "for_review"
    case completed = "completed"
    case rejected = "rejected"
    
    var displayName: String {
        switch self {
        case .assigned: return "Assigned"
        case .review: return "For Review"
        case .completed: return "Completed"
        case .rejected: return "Rejected"
        }
    }
    
    var displayColor: UIColor {
        switch self {
        case .assigned: return .systemBlue
        case .review: return .systemYellow
        case .completed: return .systemGreen
        case .rejected: return .systemRed
        }
    }
}

struct TaskModel {
    var id: String?              // Task UUID from database
    var name: String             // Assignee name or "All Members"
    var desc: String             // Task description
    var date: String             // Display date string (e.g., "03 Nov 2025")
    var remark: String?          // "Remark" or nil
    var remarkDesc: String?      // Actual remark text
    var title: String?           // Task title
    var attachments: [UIImage]?  // Local images (downloaded from storage)
    var assignedDate: Date?      // Actual Date object
    var status: String           // "assigned", "ongoing", "for_review", "completed", "rejected"
    
    init(id: String? = nil,
         name: String,
         desc: String,
         date: String,
         remark: String? = nil,
         remarkDesc: String? = nil,
         title: String? = nil,
         attachments: [UIImage]? = nil,
         assignedDate: Date? = nil,
         status: String = "assigned") {
        self.id = id
        self.name = name
        self.desc = desc
        self.date = date
        self.remark = remark
        self.remarkDesc = remarkDesc
        self.title = title
        self.attachments = attachments
        self.assignedDate = assignedDate
        self.status = status
    }
    
    // Helper to convert from Supabase TaskRow (async to download attachments)
    static func from(taskRow: SupabaseManager.TaskRow, assigneeName: String = "Team Task") async -> TaskModel {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        
        let iso8601Formatter = ISO8601DateFormatter()
        let assignedDate = iso8601Formatter.date(from: taskRow.assigned_date)
        let dateString = assignedDate.map { dateFormatter.string(from: $0) } ?? taskRow.assigned_date
        
        // Download attachments asynchronously
        var attachmentImages: [UIImage] = []
        do {
            attachmentImages = try await SupabaseManager.shared.downloadTaskAttachmentImages(taskId: taskRow.id)
        } catch {
            print("⚠️ Failed to download attachments for task \(taskRow.id): \(error)")
        }
        
        return TaskModel(
            id: taskRow.id,
            name: assigneeName,
            desc: taskRow.description ?? "",
            date: dateString,
            remark: taskRow.remark,
            remarkDesc: taskRow.remark_description,
            title: taskRow.title,
            attachments: attachmentImages.isEmpty ? nil : attachmentImages,
            assignedDate: assignedDate,
            status: taskRow.status
        )
    }
    
    // Synchronous version (without attachments) for quick display
    static func fromSync(taskRow: SupabaseManager.TaskRow, assigneeName: String = "Team Task") -> TaskModel {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        
        let iso8601Formatter = ISO8601DateFormatter()
        let assignedDate = iso8601Formatter.date(from: taskRow.assigned_date)
        let dateString = assignedDate.map { dateFormatter.string(from: $0) } ?? taskRow.assigned_date
        
        return TaskModel(
            id: taskRow.id,
            name: assigneeName,
            desc: taskRow.description ?? "",
            date: dateString,
            remark: taskRow.remark,
            remarkDesc: taskRow.remark_description,
            title: taskRow.title,
            attachments: nil,
            assignedDate: assignedDate,
            status: taskRow.status
        )
    }
}
