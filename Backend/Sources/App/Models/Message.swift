import Fluent
import Vapor

final class Message: Model, Content {
    static let schema = "messages"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "content")
    var content: String
    
    @Field(key: "sender_device_id")
    var senderDeviceId: String
    
    @Field(key: "receiver_device_id")
    var receiverDeviceId: String
    
    @Field(key: "created_at")
    var createdAt: Date
    
    @Field(key: "delivery_status")
    var deliveryStatus: String // Using String instead of enum for simplicity
    
    init() { }
    
    init(id: UUID? = nil, content: String, senderDeviceId: String, receiverDeviceId: String, createdAt: Date = Date(), deliveryStatus: String = "sent") {
        self.id = id
        self.content = content
        self.senderDeviceId = senderDeviceId
        self.receiverDeviceId = receiverDeviceId
        self.createdAt = createdAt
        self.deliveryStatus = deliveryStatus
    }
}