import Fluent
import Vapor

final class Message: Model, Content {
    static let schema = "messages"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "content") var content: String
    @Field(key: "sender_device_id") var senderDeviceId: String
    @Field(key: "receiver_device_id") var receiverDeviceId: String
    @Field(key: "status") var status: String
    
    init() { }
    init(content: String, sender: String, receiver: String) {
        self.content = content
        self.senderDeviceId = sender
        self.receiverDeviceId = receiver
        self.status = "sent"
    }
}