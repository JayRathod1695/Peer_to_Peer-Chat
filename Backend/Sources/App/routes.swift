import Vapor

func routes(_ app: Application) throws {
    app.get { _ in "Chat Backend API is running!" }
    
    try app.register(collection: ChatController())
}