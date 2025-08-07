import Vapor

@main
enum Entrypoint {
    static func main() async throws {
        let app = Application()
        defer { app.shutdown() }
        try await configure(app)
        try await app.execute()
    }
}