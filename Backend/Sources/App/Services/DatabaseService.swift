import Fluent
import Vapor

class DatabaseService {
    private let db: Database
    private let pythonBridge: PythonBridge
    
    init(db: Database, pythonBridge: PythonBridge) {
        self.db = db
        self.pythonBridge = pythonBridge
    }
    
    // MARK: - User Operations
    func createUser(email: String, username: String, passwordHash: String, deviceId: String) async throws -> User {
        let user = User(username: username, email: email, passwordHash: passwordHash, deviceId: deviceId)
        try await user.save(on: db)
        return user
    }
    
    func findUser(by email: String) async throws -> User? {
        return try await User.query(on: db)
            .filter(\.$email == email)
            .first()
    }
    
    func findUser(by id: UUID) async throws -> User? {
        return try await User.find(id, on: db)
    }
    
    // MARK: - Message Operations with Python Integration
    func saveMessage(_ message: Message) async throws -> Message {
        // Save to local database
        try await message.save(on: db)
        
        // Also save to Supabase via Python
        do {
            let _ = try await pythonBridge.saveMessage(
                deviceId: message.senderDeviceId,
                senderId: message.senderDeviceId,
                receiverId: message.receiverDeviceId,
                text: message.content
            )
        } catch {
            // Log error but don't fail the operation
            print("Failed to save message to Supabase: \(error)")
        }
        
        return message
    }
    
    func getMessages(for deviceId: String, limit: Int = 50) async throws -> [Message] {
        return try await Message.query(on: db)
            .group(.or) { group in
                group.filter(\.$senderDeviceId == deviceId)
                group.filter(\.$receiverDeviceId == deviceId)
            }
            .sort(\.$createdAt, .descending)
            .limit(limit)
            .all()
    }
    
    func getMessagesBetween(device1: String, device2: String, limit: Int = 50) async throws -> [Message] {
        return try await Message.query(on: db)
            .group(.or) { group in
                group.group(.and) { andGroup in
                    andGroup.filter(\.$senderDeviceId == device1)
                    andGroup.filter(\.$receiverDeviceId == device2)
                }
                group.group(.and) { andGroup in
                    andGroup.filter(\.$senderDeviceId == device2)
                    andGroup.filter(\.$receiverDeviceId == device1)
                }
            }
            .sort(\.$createdAt, .descending)
            .limit(limit)
            .all()
    }
    
    func updateMessageStatus(_ messageId: UUID, status: DeliveryStatus) async throws {
        guard let message = try await Message.find(messageId, on: db) else {
            throw Abort(.notFound, reason: "Message not found")
        }
        message.deliveryStatus = status
        try await message.save(on: db)
    }
    
    func getMessagePreviews(for deviceId: String) async throws -> [MessagePreview] {
        // Try to get from Supabase first
        do {
            let response = try await pythonBridge.getUsage(deviceId: deviceId)
            if let previews = response["previews"] as? [[String: Any]] {
                return previews.compactMap { previewDict in
                    guard let deviceId = previewDict["deviceId"] as? String,
                          let preview = previewDict["preview"] as? String,
                          let timestampStr = previewDict["timestamp"] as? String,
                          let unreadCount = previewDict["unreadCount"] as? Int else {
                        return nil
                    }
                    
                    let formatter = ISO8601DateFormatter()
                    let timestamp = formatter.date(from: timestampStr) ?? Date()
                    
                    return MessagePreview(
                        deviceId: deviceId,
                        preview: preview,
                        timestamp: timestamp,
                        unreadCount: unreadCount
                    )
                }
            }
        } catch {
            print("Failed to get message previews from Supabase: \(error)")
        }
        
        // Fallback to local database
        let messages = try await Message.query(on: db)
            .group(.or) { group in
                group.filter(\.$senderDeviceId == deviceId)
                group.filter(\.$receiverDeviceId == deviceId)
            }
            .sort(\.$createdAt, .descending)
            .all()
        
        var previews: [String: MessagePreview] = [:]
        
        for message in messages {
            let otherDeviceId = message.senderDeviceId == deviceId ? message.receiverDeviceId : message.senderDeviceId
            
            if previews[otherDeviceId] == nil {
                let unreadCount = try await getUnreadMessageCount(for: deviceId, from: otherDeviceId)
                previews[otherDeviceId] = MessagePreview(
                    deviceId: otherDeviceId,
                    preview: String(message.content.prefix(50)),
                    timestamp: message.createdAt!,
                    unreadCount: unreadCount
                )
            }
        }
        
        return Array(previews.values).sorted { $0.timestamp > $1.timestamp }
    }
    
    private func getUnreadMessageCount(for receiverDeviceId: String, from senderDeviceId: String) async throws -> Int {
        return try await Message.query(on: db)
            .filter(\.$receiverDeviceId == receiverDeviceId)
            .filter(\.$senderDeviceId == senderDeviceId)
            .filter(\.$deliveryStatus != .delivered)
            .count()
    }
    
    // MARK: - Connection Log Operations with Python Integration
    func logConnection(_ log: ConnectionLog) async throws -> ConnectionLog {
        // Save to local database
        try await log.save(on: db)
        
        // Also save to Supabase via Python
        do {
            let _ = try await pythonBridge.saveConnectionLog(
                localDeviceId: log.localDeviceId,
                remoteDeviceId: log.remoteDeviceId,
                status: log.status.rawValue,
                errorMessage: log.errorMessage
            )
        } catch {
            // Log error but don't fail the operation
            print("Failed to save connection log to Supabase: \(error)")
        }
        
        return log
    }
    
    func getConnectionLogs(for deviceId: String, limit: Int = 100) async throws -> [ConnectionLog] {
        return try await ConnectionLog.query(on: db)
            .group(.or) { group in
                group.filter(\.$localDeviceId == deviceId)
                group.filter(\.$remoteDeviceId == deviceId)
            }
            .sort(\.$createdAt, .descending)
            .limit(limit)
            .all()
    }
    
    func getConnectionStats(for deviceId: String) async throws -> ConnectionStats {
        // Try to get from Supabase first
        do {
            let response = try await pythonBridge.getUsage(deviceId: deviceId)
            if let stats = response["stats"] as? [String: Any],
               let attempts = stats["attempts"] as? Int,
               let successes = stats["successes"] as? Int,
               let failures = stats["failures"] as? Int {
                return ConnectionStats(attempts: attempts, successes: successes, failures: failures)
            }
        } catch {
            print("Failed to get connection stats from Supabase: \(error)")
        }
        
        // Fallback to local database
        let logs = try await getConnectionLogs(for: deviceId)
        
        let attempts = logs.filter { $0.status == .attempt }.count
        let successes = logs.filter { $0.status == .success }.count
        let failures = logs.filter { $0.status == .failure }.count
        
        return ConnectionStats(attempts: attempts, successes: successes, failures: failures)
    }
    
    // MARK: - Dummy Data Methods
    func getDummyDevices() -> [String] {
        return pythonBridge.getDummyDevices()
    }
    
    func getDummyStats() -> ConnectionStats {
        let stats = pythonBridge.getDummyStats()
        return ConnectionStats(
            attempts: stats["attempts"] as? Int ?? 5,
            successes: stats["successes"] as? Int ?? 3,
            failures: stats["failures"] as? Int ?? 2
        )
    }
    
    func getDummyMessagePreviews() -> [MessagePreview] {
        let previews = pythonBridge.getDummyPreviews()
        return previews.compactMap { previewDict in
            guard let deviceId = previewDict["deviceId"] as? String,
                  let preview = previewDict["preview"] as? String,
                  let timestampStr = previewDict["timestamp"] as? String,
                  let unreadCount = previewDict["unreadCount"] as? Int else {
                return nil
            }
            
            let formatter = ISO8601DateFormatter()
            let timestamp = formatter.date(from: timestampStr) ?? Date()
            
            return MessagePreview(
                deviceId: deviceId,
                preview: preview,
                timestamp: timestamp,
                unreadCount: unreadCount
            )
        }
    }
}

// MARK: - DTOs
struct ConnectionStats: Content {
    let attempts: Int
    let successes: Int
    let failures: Int
}

// MARK: - Dummy Data
struct DummyData {
    static let devices = ["Device 1", "Device 2", "Device 3", "iPhone 12", "MacBook Pro", "iPad Air"]
    
    static let stats = ConnectionStats(attempts: 15, successes: 12, failures: 3)
    
    static let previews: [MessagePreview] = [
        MessagePreview(
            deviceId: "Device 1",
            preview: "Hey there! How are you doing?",
            timestamp: Date().addingTimeInterval(-3600), // 1 hour ago
            unreadCount: 2
        ),
        MessagePreview(
            deviceId: "Device 2",
            preview: "Thanks for the file you sent earlier",
            timestamp: Date().addingTimeInterval(-7200), // 2 hours ago
            unreadCount: 0
        ),
        MessagePreview(
            deviceId: "iPhone 12",
            preview: "Are we still meeting tomorrow?",
            timestamp: Date().addingTimeInterval(-86400), // 1 day ago
            unreadCount: 1
        ),
        MessagePreview(
            deviceId: "MacBook Pro",
            preview: "The project looks great! 👍",
            timestamp: Date().addingTimeInterval(-172800), // 2 days ago
            unreadCount: 0
        )
    ]
    
    static func getRandomDevice() -> String {
        return devices.randomElement() ?? "Unknown Device"
    }
}
