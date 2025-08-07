import Vapor
import Fluent
import FluentSQLiteDriver

public func configure(_ app: Application) async throws {
    // Configure SQLite database
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    
    // Configure migrations
    app.migrations.add(CreateUser())
    app.migrations.add(CreateMessage())
    app.migrations.add(CreateConnectionLog())
    
    // Register routes
    try routes(app)
}