import Vapor

struct ConnectionStats: Content {
    let attempts: Int
    let successes: Int
    let failures: Int
    
    init(attempts: Int, successes: Int, failures: Int) {
        self.attempts = attempts
        self.successes = successes
        self.failures = failures
    }
}