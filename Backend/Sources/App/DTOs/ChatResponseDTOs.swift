import Vapor
import Foundation

// MARK: - Response DTOs for Chat Endpoints

struct ScanResponse: Content {
    let status: String
    let devices: [String]
    let timestamp: String
}

struct ConnectResponse: Content {
    let status: String
    let deviceId: String
    let message: String
    let timestamp: String
}

struct SendMessageResponse: Content {
    let status: String
    let deviceId: String
    let message: String
    let messageId: String
    let timestamp: String
}

struct UsageResponse: Content {
    let status: String
    let totalMessages: Int
    let totalConnections: Int
    let activeDevices: Int
    let timestamp: String
}

struct MessageResponse: Content {
    let id: String
    let senderId: String
    let content: String
    let timestamp: String
    let isOutgoing: Bool
}

struct MessagesResponse: Content {
    let status: String
    let deviceId: String
    let messages: [MessageResponse]
    let totalCount: Int
    let timestamp: String
}

struct ConversationPreview: Content {
    let deviceId: String
    let deviceName: String
    let lastMessage: String
    let lastMessageTime: String
    let unreadCount: Int
    let isConnected: Bool
}

struct ConversationsResponse: Content {
    let status: String
    let conversations: [ConversationPreview]
    let totalCount: Int
    let timestamp: String
}

// MARK: - Request DTOs

struct SendMessageRequest: Content {
    let message: String
}

// MARK: - Helper Extensions

extension Date {
    func iso8601String() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}
