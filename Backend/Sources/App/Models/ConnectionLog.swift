import Fluent
import Vapor

final class ConnectionLog: Model, Content {
    static let schema = "connection_logs"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "local_device_id")
    var localDeviceId: String
    
    @Field(key: "remote_device_id")
    var remoteDeviceId: String
    
    @Field(key: "connection_type")
    var connectionType: ConnectionType
    
    @Field(key: "status")
    var status: ConnectionStatus
    
    @Field(key: "error_message")
    var errorMessage: String?
    
    @Field(key: "duration")
    var duration: Double? // Connection duration in seconds
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, localDeviceId: String, remoteDeviceId: String, connectionType: ConnectionType, status: ConnectionStatus, errorMessage: String? = nil, duration: Double? = nil) {
        self.id = id
        self.localDeviceId = localDeviceId
        self.remoteDeviceId = remoteDeviceId
        self.connectionType = connectionType
        self.status = status
        self.errorMessage = errorMessage
        self.duration = duration
    }
}

enum ConnectionType: String, Codable, CaseIterable {
    case incoming = "incoming"
    case outgoing = "outgoing"
}

enum ConnectionStatus: String, Codable, CaseIterable {
    case attempt = "attempt"
    case success = "success"
    case failure = "failure"
    case disconnected = "disconnected"
}

// Migration
struct CreateConnectionLog: AsyncMigration {
    func prepare(on database: Database) async throws {
        let connectionTypeEnum = try await database.enum("connection_type")
            .case("incoming")
            .case("outgoing")
            .create()
        
        let connectionStatusEnum = try await database.enum("connection_status")
            .case("attempt")
            .case("success")
            .case("failure")
            .case("disconnected")
            .create()
        
        try await database.schema("connection_logs")
            .id()
            .field("local_device_id", .string, .required)
            .field("remote_device_id", .string, .required)
            .field("connection_type", connectionTypeEnum, .required)
            .field("status", connectionStatusEnum, .required)
            .field("error_message", .string)
            .field("duration", .double)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("connection_logs").delete()
        try await database.enum("connection_type").delete()
        try await database.enum("connection_status").delete()
    }
}

// DTOs
struct ConnectionLogResponse: Content {
    let id: UUID
    let localDeviceId: String
    let remoteDeviceId: String
    let connectionType: ConnectionType
    let status: ConnectionStatus
    let errorMessage: String?
    let duration: Double?
    let createdAt: Date
    
    init(from log: ConnectionLog) {
        self.id = log.id!
        self.localDeviceId = log.localDeviceId
        self.remoteDeviceId = log.remoteDeviceId
        self.connectionType = log.connectionType
        self.status = log.status
        self.errorMessage = log.errorMessage
        self.duration = log.duration
        self.createdAt = log.createdAt!
    }
}
