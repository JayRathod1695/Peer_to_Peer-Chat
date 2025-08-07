import Vapor
import Foundation

// Response structs
struct ScanResponse: Content {
    let devices: [String]
}

struct ConnectResponse: Content {
    let success: Bool
    let message: String
}

struct SendMessageResponse: Content {
    let success: Bool
    let messageId: String?
    let message: String
}

struct UsageResponse: Content {
    let stats: ConnectionStats
    let previews: [MessagePreview]
}

struct ChatController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("scan", use: scan)
        routes.post("connect", ":deviceId", use: connect)
        routes.post("sendMessage", ":deviceId", use: sendMessage)
        routes.get("usage", use: usage)
    }
    
    func scan(req: Request) async throws -> ScanResponse {
        // In a real implementation, this would use BluetoothManager
        // For now, return an empty list
        return ScanResponse(devices: [])
    }
    
    func connect(req: Request) async throws -> ConnectResponse {
        guard let deviceId = req.parameters.get("deviceId") else {
            throw Abort(.badRequest, reason: "Device ID is required")
        }
        
        // In a real implementation, this would use BluetoothManager
        // For now, return a success response
        return ConnectResponse(success: true, message: "Connected to \(deviceId)")
    }
    
    func sendMessage(req: Request) async throws -> SendMessageResponse {
        guard let deviceId = req.parameters.get("deviceId") else {
            throw Abort(.badRequest, reason: "Device ID is required")
        }
        
        struct MessageRequest: Content {
            let content: String
        }
        
        let messageRequest = try req.content.decode(MessageRequest.self)
        
        // In a real implementation, this would use BluetoothManager
        // For now, return a success response
        let messageId = UUID().uuidString
        return SendMessageResponse(
            success: true,
            messageId: messageId,
            message: "Message sent to \(deviceId)"
        )
    }
    
    func usage(req: Request) async throws -> UsageResponse {
        // In a real implementation, this would get data from DatabaseService
        // For now, return default values
        let stats = ConnectionStats(attempts: 0, successes: 0, failures: 0)
        let previews: [MessagePreview] = []
        return UsageResponse(stats: stats, previews: previews)
    }
}