import Vapor
import Foundation

struct ChatController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("scan", use: scan)
        routes.post("connect", ":deviceId", use: connect)
        routes.post("sendMessage", ":deviceId", use: sendMessage)
        routes.get("usage", use: usage)
    }
    
    func scan(req: Request) async throws -> [String: Any] {
        return ["devices": ["Device 1", "iPhone 12", "MacBook Pro"]]
    }
    
    func connect(req: Request) async throws -> [String: Any] {
        let deviceId = req.parameters.get("deviceId") ?? ""
        return ["status": "connected", "deviceId": deviceId]
    }
    
    func sendMessage(req: Request) async throws -> [String: Any] {
        let deviceId = req.parameters.get("deviceId") ?? ""
        let content = try req.content.decode([String: String].self)["message"] ?? ""
        return ["status": "sent", "message": content, "deviceId": deviceId]
    }
    
    func usage(req: Request) async throws -> [String: Any] {
        return ["stats": ["attempts": 15, "successes": 12, "failures": 3]]
    }
}