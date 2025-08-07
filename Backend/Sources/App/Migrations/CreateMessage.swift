import Fluent

struct CreateMessage: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("messages")
            .id()
            .field("content", .string, .required)
            .field("sender_device_id", .string, .required)
            .field("receiver_device_id", .string, .required)
            .field("created_at", .datetime, .required)
            .field("delivery_status", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("messages").delete()
    }
}