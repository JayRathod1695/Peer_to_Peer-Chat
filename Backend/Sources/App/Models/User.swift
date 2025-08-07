import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "email") var email: String
    @Field(key: "username") var username: String
    @Field(key: "device_id") var deviceId: String
    
    init() { }
    init(id: UUID? = nil, email: String, username: String, deviceId: String) {
        self.id = id
        self.email = email
        self.username = username
        self.deviceId = deviceId
    }
}