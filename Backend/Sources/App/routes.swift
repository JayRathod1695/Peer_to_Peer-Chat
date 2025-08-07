import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return "It works!"
    }

    app.get("hello") { req in
        return "Hello, world!"
    }
    
    // Register route collections
    try app.register(collection: ChatController())
    try app.register(collection: AuthController())
}