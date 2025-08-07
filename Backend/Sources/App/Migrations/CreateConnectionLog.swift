import Fluent

struct CreateConnectionLog: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("connection_logs")
            .id()
            .field("local_device_id", .string, .required)
            .field("remote_device_id", .string, .required)
            .field("status", .string, .required)
            .field("created_at", .datetime, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("connection_logs").delete()
    }
}