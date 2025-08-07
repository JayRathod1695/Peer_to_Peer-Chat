import Fluent
import Vapor

final class ConnectionLog: Model, Content, @unchecked Sendable {
    static let schema = "connection_logs"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "local_device_id")
    var localDeviceId: String
    
    @Field(key: "remote_device_id")
    var remoteDeviceId: String
    
    @Field(key: "status")
    var status: String
    
    @Field(key: "created_at")
    var createdAt: Date
    
    init() { }
    
    init(id: UUID? = nil, localDeviceId: String, remoteDeviceId: String, status: String, createdAt: Date = Date()) {
        self.id = id
        self.localDeviceId = localDeviceId
        self.remoteDeviceId = remoteDeviceId
        self.status = status
        self.createdAt = createdAt
    }
}