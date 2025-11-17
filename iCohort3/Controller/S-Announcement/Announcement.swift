//
//  Announcement.swift
//  iCohort3
//

//
//  Announcement.swift
//  iCohort3
//

import UIKit

enum AttachmentType {
    case image(UIImage)
    case pdf(String, URL) // title and URL
    case link(String, URL) // title and URL
}

struct Announcement {
    let id: UUID
    let title: String
    let body: String
    let tag: String?
    let tagColor: UIColor?  // Add this
    let createdAt: Date
    let author: String
    var attachments: [AttachmentType]?
    
    init(id: UUID, title: String, body: String, tag: String?, tagColor: UIColor? = nil, createdAt: Date, author: String, attachments: [AttachmentType]? = nil) {
        self.id = id
        self.title = title
        self.body = body
        self.tag = tag
        self.tagColor = tagColor
        self.createdAt = createdAt
        self.author = author
        self.attachments = attachments
    }
}
