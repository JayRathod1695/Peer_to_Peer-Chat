import Foundation
import Vapor

class PythonBridge {
    func runScript(_ script: String, args: [String]) async throws -> [String: Any] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = ["./python/supabase_client.py"] + args
        
        let output = Pipe()
        process.standardOutput = output
        
        try process.run()
        process.waitUntilExit()
        
        let data = output.fileHandleForReading.readDataToEndOfFile()
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        return json
    }
}