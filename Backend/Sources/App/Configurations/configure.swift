import Vapor
import Fluent
import FluentSQLiteDriver

public func configure(_ app: Application) async throws {
    // Configure SQLite database
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    
    // Configure migrations
    // Add your migrations here when you create models
    // app.migrations.add(CreateUser())
    
    // Register routes
    try routes(app)
}