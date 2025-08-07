import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .id()
            .field("email", .string, .required)
            .field("username", .string, .required)
            .field("password_hash", .string, .required)
            .field("device_id", .string, .required)
            .field("created_at", .datetime)
            .unique(on: "email")
            .unique(on: "device_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}