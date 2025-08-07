import Fluent
import Vapor

class DatabaseService {
    let db: Database
    let pythonBridge: PythonBridge
    
    init(db: Database) {
        self.db = db
        self.pythonBridge = PythonBridge()
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
        
        // Also save to Supabase via Python
        do {
            let _ = try await pythonBridge.saveMessageToSupabase(
                deviceId: message.senderDeviceId,
                senderId: message.senderDeviceId,
                receiverId: message.receiverDeviceId,
                content: message.content,
                timestamp: message.createdAt
            )
        } catch {
            print("Failed to save message to Supabase: \(error)")
        }
        
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
        // Try to get from Supabase first
        do {
            let response = try await pythonBridge.getUsageFromSupabase(deviceId: deviceId)
            if let previews = response["previews"] as? [[String: Any]] {
                return previews.compactMap { previewDict in
                    guard let deviceId = previewDict["deviceId"] as? String,
                          let lastMessage = previewDict["lastMessage"] as? String,
                          let timestamp = previewDict["timestamp"] as? Date,
                          let unreadCount = previewDict["unreadCount"] as? Int else {
                        return nil
                    }
                    return MessagePreview(
                        deviceId: deviceId,
                        lastMessage: lastMessage,
                        timestamp: timestamp,
                        unreadCount: unreadCount
                    )
                }
            }
        } catch {
            print("Failed to get previews from Supabase: \(error)")
        }
        
        // Fallback to local database
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
        
        // Also save to Supabase via Python
        do {
            let _ = try await pythonBridge.saveConnectionLogToSupabase(
                localDeviceId: log.localDeviceId,
                remoteDeviceId: log.remoteDeviceId,
                status: log.status,
                timestamp: log.createdAt
            )
        } catch {
            print("Failed to save connection log to Supabase: \(error)")
        }
        
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
        // Try to get from Supabase first
        do {
            let response = try await pythonBridge.getUsageFromSupabase(deviceId: deviceId)
            if let stats = response["stats"] as? [String: Any],
               let attempts = stats["attempts"] as? Int,
               let successes = stats["successes"] as? Int,
               let failures = stats["failures"] as? Int {
                return ConnectionStats(attempts: attempts, successes: successes, failures: failures)
            }
        } catch {
            print("Failed to get stats from Supabase: \(error)")
        }
        
        // Fallback to local database
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
    
    // MARK: - Dummy Data Methods
    func getDummyDevices() -> [String] {
        return pythonBridge.getDummyDevicesFromPython()
    }
    
    func getDummyStats() -> ConnectionStats {
        let stats = pythonBridge.getDummyStatsFromPython()
        return ConnectionStats(
            attempts: stats["attempts"] ?? 5,
            successes: stats["successes"] ?? 3,
            failures: stats["failures"] ?? 2
        )
    }
    
    func getDummyMessagePreviews() -> [MessagePreview] {
        let previews = pythonBridge.getDummyPreviewsFromPython()
        return previews.compactMap { previewDict in
            guard let deviceId = previewDict["deviceId"] as? String,
                  let lastMessage = previewDict["lastMessage"] as? String,
                  let timestamp = previewDict["timestamp"] as? Date,
                  let unreadCount = previewDict["unreadCount"] as? Int else {
                return nil
            }
            return MessagePreview(
                deviceId: deviceId,
                lastMessage: lastMessage,
                timestamp: timestamp,
                unreadCount: unreadCount
            )
        }
    }
    
    static let stats = ConnectionStats(attempts: 15, successes: 12, failures: 3)
    
    static let previews: [MessagePreview] = [
        MessagePreview(
            deviceId: "Device 1",
            lastMessage: "Hello there!",
            timestamp: Date().addingTimeInterval(-3600),
            unreadCount: 2
        ),
        MessagePreview(
            deviceId: "Device 2",
            lastMessage: "How are you?",
            timestamp: Date().addingTimeInterval(-7200),
            unreadCount: 0
        ),
        MessagePreview(
            deviceId: "Device 3",
            lastMessage: "Meeting at 3 PM",
            timestamp: Date().addingTimeInterval(-10800),
            unreadCount: 5
        )
    ]
}