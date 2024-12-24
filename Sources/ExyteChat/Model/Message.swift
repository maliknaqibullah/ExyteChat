//
//  Message.swift
//  Chat
//
//  Created by Alisa Mylnikova on 20.04.2022.
//

import SwiftUI

open class Message: ObservableObject, Identifiable {

    public enum Status: Equatable, Hashable, Sendable {
        case sending
        case sent
        case read
        case error(DraftMessage)

        public func hash(into hasher: inout Hasher) {
            switch self {
            case .sending:
                return hasher.combine("sending")
            case .sent:
                return hasher.combine("sent")
            case .read:
                return hasher.combine("read")
            case .error:
                return hasher.combine("error")
            }
        }

        public static func == (lhs: Message.Status, rhs: Message.Status) -> Bool {
            switch (lhs, rhs) {
            case (.sending, .sending):
                return true
            case (.sent, .sent):
                return true
            case (.read, .read):
                return true
            case ( .error(_), .error(_)):
                return true
            default:
                return false
            }
        }
    }

    @Published public var id: String
    @Published public var user: User
    @Published public var status: Status?
    @Published public var createdAt: Date

    @Published public var text: String
    @Published public var attachments: [Attachment]
    @Published public var reactions: [Reaction]
    @Published public var giphyMediaId: String?
    @Published public var recording: Recording?
    @Published public var replyMessage: ReplyMessage?

    @Published public var triggerRedraw: UUID?

    public init(id: String,
                user: User,
                status: Status? = nil,
                createdAt: Date = Date(),
                text: String = "",
                attachments: [Attachment] = [],
                giphyMediaId: String? = nil,
                reactions: [Reaction] = [],
                recording: Recording? = nil,
                replyMessage: ReplyMessage? = nil) {

        self.id = id
        self.user = user
        self.status = status
        self.createdAt = createdAt
        self.text = text
        self.attachments = attachments
        self.giphyMediaId = giphyMediaId
        self.reactions = reactions
        self.recording = recording
        self.replyMessage = replyMessage
    }

    public static func makeMessage(
        id: String,
        user: User,
        status: Status? = nil,
        draft: DraftMessage) async -> Message {
            let attachments = await draft.medias.asyncCompactMap { media -> Attachment? in
                guard let thumbnailURL = await media.getThumbnailURL() else {
                    return nil
                }
                
                switch media.type {
                case .image:
                    return Attachment(id: UUID().uuidString, url: thumbnailURL, type: .image)
                case .video:
                    guard let fullURL = await media.getURL() else {
                        return nil
                    }
                    return Attachment(id: UUID().uuidString, thumbnail: thumbnailURL, full: fullURL, type: .video)
                }
            }
            
            let giphyMediaId = draft.giphyMedia?.id
            
            return Message(
                id: id,
                user: user,
                status: status,
                createdAt: draft.createdAt,
                text: draft.text,
                attachments: attachments,
                giphyMediaId: giphyMediaId,
                recording: draft.recording,
                replyMessage: draft.replyMessage
            )
        }
}

extension Message {
    var time: String {
        DateFormatter.timeFormatter.string(from: createdAt)
    }
}

extension Message: Equatable {
    public static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id &&
        lhs.user == rhs.user &&
        lhs.status == rhs.status &&
        lhs.createdAt == rhs.createdAt &&
        lhs.text == rhs.text &&
        lhs.giphyMediaId == rhs.giphyMediaId &&
        lhs.attachments == rhs.attachments &&
        lhs.reactions == rhs.reactions &&
        lhs.recording == rhs.recording &&
        lhs.replyMessage == rhs.replyMessage
    }
}

extension Message: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.user)
        hasher.combine(self.status)
        hasher.combine(self.createdAt)
        hasher.combine(self.text)
        hasher.combine(self.attachments)
        hasher.combine(self.recording)
        hasher.combine(self.replyMessage)
    }
}

public class Recording: ObservableObject, Codable {
    private enum CodingKeys: CodingKey {
        case duration
        case waveformSamples
        case url
    }

    @Published public var duration: Double
    @Published public var waveformSamples: [CGFloat]
    @Published public var url: URL?

    public init(duration: Double = 0.0, waveformSamples: [CGFloat] = [], url: URL? = nil) {
        self.duration = duration
        self.waveformSamples = waveformSamples
        self.url = url
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        duration = try container.decode(Double.self, forKey: .duration)
        waveformSamples = try container.decode([CGFloat].self, forKey: .waveformSamples)
        url = try container.decode(URL?.self, forKey: .url)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(duration, forKey: .duration)
        try container.encode(waveformSamples, forKey: .waveformSamples)
        try container.encode(url, forKey: .url)
    }
}

extension Recording: Equatable {
    public static func == (lhs: Recording, rhs: Recording) -> Bool {
        lhs.duration == rhs.duration &&
        lhs.waveformSamples == rhs.waveformSamples &&
        lhs.url == rhs.url
    }
}
    
extension Recording: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.duration)
        hasher.combine(self.waveformSamples)
        hasher.combine(self.url)
    }
}

public class ReplyMessage: ObservableObject, Codable, Identifiable {
    private enum CodingKeys: CodingKey {
        case id
        case user
        case createdAt
        case text
        case attachments
        case recording
    }

    @Published public var id: String
    @Published public var user: User
    @Published public var createdAt: Date

    @Published public var text: String
    @Published public var attachments: [Attachment]
    @Published public var recording: Recording?

    public init(id: String,
                user: User,
                createdAt: Date,
                text: String = "",
                attachments: [Attachment] = [],
                recording: Recording? = nil) {

        self.id = id
        self.user = user
        self.createdAt = createdAt
        self.text = text
        self.attachments = attachments
        self.recording = recording
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        user = try container.decode(User.self, forKey: .user)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        text = try container.decode(String.self, forKey: .text)
        attachments = try container.decode([Attachment].self, forKey: .attachments)
        recording = try container.decode(Recording?.self, forKey: .recording)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(user, forKey: .user)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(text, forKey: .text)
        try container.encode(attachments, forKey: .attachments)
        try container.encode(recording, forKey: .recording)
    }

    func toMessage() -> Message {
        Message(id: id, user: user, createdAt: createdAt, text: text, attachments: attachments, recording: recording)
    }
}

extension ReplyMessage: Equatable {
    public static func == (lhs: ReplyMessage, rhs: ReplyMessage) -> Bool {
        lhs.id == rhs.id &&
        lhs.user == rhs.user &&
        lhs.createdAt == rhs.createdAt &&
        lhs.text == rhs.text &&
        lhs.attachments == rhs.attachments &&
        lhs.recording == rhs.recording
    }
}

extension ReplyMessage: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.user)
        hasher.combine(self.createdAt)
        hasher.combine(self.text)
        hasher.combine(self.attachments)
        hasher.combine(self.recording)
    }
}

public extension Message {

    func toReplyMessage() -> ReplyMessage {
        ReplyMessage(id: id, user: user, createdAt: createdAt, text: text, attachments: attachments, recording: recording)
    }
}
