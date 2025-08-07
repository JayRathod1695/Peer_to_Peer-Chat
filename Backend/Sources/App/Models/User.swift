import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Field(key: "device_id")
    var deviceId: String
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, username: String, email: String, passwordHash: String, deviceId: String) {
        self.id = id
        self.username = username
        self.email = email
        self.passwordHash = passwordHash
        self.deviceId = deviceId
    }
}