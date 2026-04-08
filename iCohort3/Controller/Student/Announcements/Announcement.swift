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

private struct PersistedAnnouncementAttachment: Codable {
    let kind: String
    let title: String
    let dataBase64: String?
    let urlString: String?
    let fileExtension: String?
}

private struct PersistedAnnouncementPayload: Codable {
    let attachments: [PersistedAnnouncementAttachment]
}

enum AnnouncementPayloadCodec {
    private static let markerPrefix = "<!--ICOHORT_ATTACHMENTS:"
    private static let markerSuffix = "-->"

    static func encodedDescription(body: String?, attachments: [AttachmentType]) -> String? {
        let visibleBody = body ?? ""
        guard !attachments.isEmpty else {
            return visibleBody.isEmpty ? nil : visibleBody
        }

        let persisted = attachments.compactMap { attachment -> PersistedAnnouncementAttachment? in
            switch attachment {
            case .image(let image):
                guard let data = image.jpegData(compressionQuality: 0.82) else { return nil }
                return PersistedAnnouncementAttachment(
                    kind: "image",
                    title: "image.jpg",
                    dataBase64: data.base64EncodedString(),
                    urlString: nil,
                    fileExtension: "jpg"
                )
            case .pdf(let title, let url):
                guard let data = try? Data(contentsOf: url) else { return nil }
                let ext = url.pathExtension.isEmpty ? "pdf" : url.pathExtension
                return PersistedAnnouncementAttachment(
                    kind: "document",
                    title: title,
                    dataBase64: data.base64EncodedString(),
                    urlString: nil,
                    fileExtension: ext
                )
            case .link(let title, let url):
                return PersistedAnnouncementAttachment(
                    kind: "link",
                    title: title,
                    dataBase64: nil,
                    urlString: url.absoluteString,
                    fileExtension: nil
                )
            }
        }

        guard !persisted.isEmpty,
              let payloadData = try? JSONEncoder().encode(PersistedAnnouncementPayload(attachments: persisted))
        else {
            return visibleBody.isEmpty ? nil : visibleBody
        }

        let payloadString = payloadData.base64EncodedString()
        let marker = "\(markerPrefix)\(payloadString)\(markerSuffix)"

        if visibleBody.isEmpty {
            return marker
        }
        return "\(visibleBody)\n\n\(marker)"
    }

    static func decodeDescription(_ rawDescription: String?) -> (body: String, attachments: [AttachmentType]) {
        guard let rawDescription, !rawDescription.isEmpty else {
            return ("", [])
        }

        guard let startRange = rawDescription.range(of: markerPrefix, options: .backwards),
              let endRange = rawDescription.range(of: markerSuffix, range: startRange.upperBound..<rawDescription.endIndex)
        else {
            return (rawDescription, [])
        }

        let payloadBase64 = String(rawDescription[startRange.upperBound..<endRange.lowerBound])
        let bodyPortion = String(rawDescription[..<startRange.lowerBound])
            .replacingOccurrences(of: "\n\n", with: "\n", options: .backwards)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let payloadData = Data(base64Encoded: payloadBase64),
              let payload = try? JSONDecoder().decode(PersistedAnnouncementPayload.self, from: payloadData)
        else {
            return (bodyPortion, [])
        }

        let attachments = payload.attachments.compactMap { makeAttachment(from: $0) }
        return (bodyPortion, attachments)
    }

    private static func makeAttachment(from persisted: PersistedAnnouncementAttachment) -> AttachmentType? {
        switch persisted.kind {
        case "image":
            guard let dataBase64 = persisted.dataBase64,
                  let data = Data(base64Encoded: dataBase64),
                  let image = UIImage(data: data) else {
                return nil
            }
            return .image(image)

        case "document":
            guard let dataBase64 = persisted.dataBase64,
                  let data = Data(base64Encoded: dataBase64) else {
                return nil
            }
            let ext = persisted.fileExtension?.isEmpty == false ? persisted.fileExtension! : "pdf"
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(ext)
            do {
                try data.write(to: tempURL, options: .atomic)
                return .pdf(persisted.title, tempURL)
            } catch {
                return nil
            }

        case "link":
            guard let urlString = persisted.urlString,
                  let url = URL(string: urlString) else {
                return nil
            }
            return .link(persisted.title, url)

        default:
            return nil
        }
    }
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
