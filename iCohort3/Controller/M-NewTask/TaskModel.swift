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
    var attachmentFilenames: [String]? // Filenames including URLs for links
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
         attachmentFilenames: [String]? = nil,
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
        self.attachmentFilenames = attachmentFilenames
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
        var attachmentFilenames: [String] = []
        
        do {
            let attachmentRows = try await SupabaseManager.shared.fetchTaskAttachments(taskId: taskRow.id)
            
            for attachmentRow in attachmentRows {
                attachmentFilenames.append(attachmentRow.filename)
                
                // Check if it's a link
                if attachmentRow.file_type == "link" {
                    // Create placeholder for link
                    let linkPlaceholder = createLinkPlaceholderImage()
                    attachmentImages.append(linkPlaceholder)
                } else if let base64Data = attachmentRow.file_data,
                          let imageData = Data(base64Encoded: base64Data),
                          let image = UIImage(data: imageData) {
                    attachmentImages.append(image)
                }
            }
            
            print("✅ Loaded \(attachmentImages.count) attachments for task \(taskRow.id)")
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
            attachmentFilenames: attachmentFilenames.isEmpty ? nil : attachmentFilenames,
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
            attachmentFilenames: nil,
            assignedDate: assignedDate,
            status: taskRow.status
        )
    }
    
    // Helper to create link placeholder image
    private static func createLinkPlaceholderImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            UIColor.systemBlue.withAlphaComponent(0.1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            let iconConfig = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
            let linkIcon = UIImage(systemName: "link", withConfiguration: iconConfig)
            linkIcon?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal).draw(in: CGRect(x: 30, y: 30, width: 40, height: 40))
        }
        
        return image
    }
}
