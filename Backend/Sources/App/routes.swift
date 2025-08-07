import Vapor

// Response structs for better type safety
struct BluetoothMessageResponse: Content {
    let message: String
}

struct DevicesResponse: Content {
    let devices: [String]
}

struct SendResponse: Content {
    let message: String
}

struct MessageRequest: Content {
    let message: String
}

func routes(_ app: Application) throws {
    app.get { req in
        return "It works!"
    }

    app.get("hello") { req in
        return "Hello, world!"
    }
    
    // Bluetooth routes
    app.get("bluetooth", "scan") { req -> BluetoothMessageResponse in
        // This would trigger scanning in a real implementation
        return BluetoothMessageResponse(message: "Bluetooth scanning started")
    }
    
    app.get("bluetooth", "devices") { req -> DevicesResponse in
        // This would return discovered devices
        return DevicesResponse(devices: [])
    }
    
    app.post("bluetooth", "connect") { req -> BluetoothMessageResponse in
        // This would handle connection requests
        return BluetoothMessageResponse(message: "Connection request received")
    }
    
    app.post("bluetooth", "send") { req async throws -> SendResponse in
        let messageData = try req.content.decode(MessageRequest.self)
        // This would send the message via Bluetooth
        return SendResponse(message: "Message sent: \(messageData.message)")
    }
}