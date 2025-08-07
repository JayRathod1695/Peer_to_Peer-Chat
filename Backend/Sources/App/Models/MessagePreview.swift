import Vapor

struct MessagePreview: Content {
    let deviceId: String
    let lastMessage: String
    let timestamp: Date
    let unreadCount: Int
    
    init(deviceId: String, lastMessage: String, timestamp: Date, unreadCount: Int) {
        self.deviceId = deviceId
        self.lastMessage = lastMessage
        self.timestamp = timestamp
        self.unreadCount = unreadCount
    }
}