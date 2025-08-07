import Vapor
import Foundation

// MARK: - Response DTOs for Chat Endpoints

struct ScanResponseDTO: Content {
    let status: String
    let devices: [String]
    let timestamp: String
}

struct ConnectResponseDTO: Content {
    let status: String
    let deviceId: String
    let message: String
    let timestamp: String
}

struct SendMessageResponseDTO: Content {
    let status: String
    let deviceId: String
    let message: String
    let messageId: String
    let timestamp: String
}

struct UsageResponseDTO: Content {
    let status: String
    let totalMessages: Int
    let totalConnections: Int
    let activeDevices: Int
    let timestamp: String
}

struct MessageResponseDTO: Content {
    let id: String
    let senderId: String
    let content: String
    let timestamp: String
    let isOutgoing: Bool
}

struct MessagesResponseDTO: Content {
    let status: String
    let deviceId: String
    let messages: [MessageResponseDTO]
    let totalCount: Int
    let timestamp: String
}

struct ConversationPreviewDTO: Content {
    let deviceId: String
    let deviceName: String
    let lastMessage: String
    let lastMessageTime: String
    let unreadCount: Int
    let isConnected: Bool
}

struct ConversationsResponseDTO: Content {
    let status: String
    let conversations: [ConversationPreviewDTO]
    let totalCount: Int
    let timestamp: String
}

// MARK: - Request DTOs

struct SendMessageRequestDTO: Content {
    let message: String
}

// MARK: - Helper Extensions

extension Date {
    func iso8601String() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}
