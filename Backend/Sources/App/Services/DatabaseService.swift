import Fluent
import Vapor

class DatabaseService {
    let db: Database
    
    init(db: Database) {
        self.db = db
    }
    
    // MARK: - User Operations
    func createUser(email: String, username: String, passwordHash: String, deviceId: String) async throws -> User {
        let user = User(username: username, email: email, passwordHash: passwordHash, deviceId: deviceId)
        try await user.save(on: db)
        return user
    }
    
    func getUserByEmail(_ email: String) async throws -> User? {
        return try await User.query(on: db)
            .filter(\.$email == email)
            .first()
    }
    
    func getUserByDeviceId(_ deviceId: String) async throws -> User? {
        return try await User.query(on: db)
            .filter(\.$deviceId == deviceId)
            .first()
    }
    
    // MARK: - Message Operations
    func saveMessage(content: String, senderDeviceId: String, receiverDeviceId: String) async throws -> Message {
        let message = Message(
            content: content,
            senderDeviceId: senderDeviceId,
            receiverDeviceId: receiverDeviceId
        )
        try await message.save(on: db)
        return message
    }
    
    func getMessages(for deviceId: String, limit: Int = 20) async throws -> [Message] {
        return try await Message.query(on: db)
            .group(.or) { group in
                group.filter(\.$receiverDeviceId == deviceId)
                group.filter(\.$senderDeviceId == deviceId)
            }
            .sort(\.$createdAt, .descending)
            .limit(limit)
            .all()
    }
    
    func getUnreadMessages(for deviceId: String, limit: Int = 20) async throws -> [Message] {
        return try await Message.query(on: db)
            .filter(\.$receiverDeviceId == deviceId)
            .filter(\.$deliveryStatus != "delivered")
            .sort(\.$createdAt, .descending)
            .limit(limit)
            .all()
    }
    
    func updateMessageStatus(_ messageId: UUID, status: String) async throws {
        guard let message = try await Message.find(messageId, on: db) else {
            throw Abort(.notFound, reason: "Message not found")
        }
        message.deliveryStatus = status
        try await message.save(on: db)
    }
    
    func getMessagePreviews(for deviceId: String) async throws -> [MessagePreview] {
        // Get message previews from local database
        let messages = try await Message.query(on: db)
            .group(.or) { group in
                group.filter(\.$receiverDeviceId == deviceId)
                group.filter(\.$senderDeviceId == deviceId)
            }
            .sort(\.$createdAt, .descending)
            .all()
        
        var previews: [String: MessagePreview] = [:]
        
        for message in messages {
            let otherDeviceId = message.senderDeviceId == deviceId ? message.receiverDeviceId : message.senderDeviceId
            
            if previews[otherDeviceId] == nil {
                previews[otherDeviceId] = MessagePreview(
                    deviceId: otherDeviceId,
                    lastMessage: message.content,
                    timestamp: message.createdAt,
                    unreadCount: message.receiverDeviceId == deviceId && message.deliveryStatus != "delivered" ? 1 : 0
                )
            } else {
                let currentPreview = previews[otherDeviceId]!
                let unreadCount = currentPreview.unreadCount + (message.receiverDeviceId == deviceId && message.deliveryStatus != "delivered" ? 1 : 0)
                previews[otherDeviceId] = MessagePreview(
                    deviceId: otherDeviceId,
                    lastMessage: message.content,
                    timestamp: message.createdAt,
                    unreadCount: unreadCount
                )
            }
        }
        
        return Array(previews.values)
    }
    
    // MARK: - Connection Log Operations
    func saveConnectionLog(localDeviceId: String, remoteDeviceId: String, status: String) async throws -> ConnectionLog {
        let log = ConnectionLog(
            localDeviceId: localDeviceId,
            remoteDeviceId: remoteDeviceId,
            status: status
        )
        try await log.save(on: db)
        return log
    }
    
    func getPendingMessagesCount(senderDeviceId: String, receiverDeviceId: String) async throws -> Int {
        return try await Message.query(on: db)
            .filter(\.$receiverDeviceId == receiverDeviceId)
            .filter(\.$senderDeviceId == senderDeviceId)
            .filter(\.$deliveryStatus != "delivered")
            .count()
    }
    
    func getConnectionStats(for deviceId: String) async throws -> ConnectionStats {
        let totalAttempts = try await ConnectionLog.query(on: db)
            .filter(\.$localDeviceId == deviceId)
            .count()
        
        let successes = try await ConnectionLog.query(on: db)
            .filter(\.$localDeviceId == deviceId)
            .filter(\.$status == "success")
            .count()
        
        let failures = totalAttempts - successes
        
        return ConnectionStats(attempts: totalAttempts, successes: successes, failures: failures)
    }
}