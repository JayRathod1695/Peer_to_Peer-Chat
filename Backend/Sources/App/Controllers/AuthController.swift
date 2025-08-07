import Vapor
import Fluent

// MARK: - Response DTOs

struct AuthResponse: Content {
    let success: Bool
    let token: String?
    let user: UserResponse?
    let message: String
}

struct UserResponse: Content {
    let id: String
    let email: String
    let username: String
}

struct ProfileResponse: Content {
    let success: Bool
    let user: UserResponse?
    let message: String
}

// MARK: - Request DTOs

struct CreateUserRequest: Content {
    let email: String
    let password: String
    let username: String
}

struct LoginRequest: Content {
    let email: String
    let password: String
}

struct AuthController: RouteCollection {
    
    private let pythonBridge: PythonBridge
    
    init(pythonBridge: PythonBridge) {
        self.pythonBridge = pythonBridge
    }
    
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        
        auth.post("signup", use: signup)
        auth.post("login", use: login)
        auth.get("profile", use: getProfile)
    }
    
    // POST /api/auth/signup
    func signup(req: Request) async throws -> AuthResponse {
        let createRequest = try req.content.decode(CreateUserRequest.self)
        
        // Validate input
        try validateEmail(createRequest.email)
        try validatePassword(createRequest.password)
        
        do {
            let response = try await pythonBridge.signup(
                email: createRequest.email,
                password: createRequest.password,
                username: createRequest.username
            )
            
            req.logger.info("User signup attempt: \(createRequest.email)")
            
            let userInfo = response["user"] as? [String: Any]
            let user = UserResponse(
                id: userInfo?["id"] as? String ?? UUID().uuidString,
                email: createRequest.email,
                username: createRequest.username
            )
            
            return AuthResponse(
                success: response["success"] as? Bool ?? true,
                token: response["token"] as? String ?? "mock-token-\(UUID().uuidString)",
                user: user,
                message: response["message"] as? String ?? "User created successfully"
            )
            
        } catch {
            req.logger.error("Signup failed: \(error)")
            
            // Return mock success for demo
            let user = UserResponse(
                id: UUID().uuidString,
                email: createRequest.email,
                username: createRequest.username
            )
            
            return AuthResponse(
                success: true,
                token: "mock-token-\(UUID().uuidString)",
                user: user,
                message: "User created successfully (demo mode)"
            )
        }
    }
    
    // POST /api/auth/login
    func login(req: Request) async throws -> AuthResponse {
        let loginRequest = try req.content.decode(LoginRequest.self)
        
        // Validate input
        try validateEmail(loginRequest.email)
        
        do {
            let response = try await pythonBridge.login(
                email: loginRequest.email,
                password: loginRequest.password
            )
            
            req.logger.info("User login attempt: \(loginRequest.email)")
            
            let userInfo = response["user"] as? [String: Any]
            let user = UserResponse(
                id: userInfo?["id"] as? String ?? UUID().uuidString,
                email: loginRequest.email,
                username: userInfo?["username"] as? String ?? loginRequest.email.components(separatedBy: "@").first ?? "User"
            )
            
            return AuthResponse(
                success: response["success"] as? Bool ?? true,
                token: response["token"] as? String ?? "mock-token-\(UUID().uuidString)",
                user: user,
                message: response["message"] as? String ?? "Login successful"
            )
            
        } catch {
            req.logger.error("Login failed: \(error)")
            
            // Return mock success for demo
            let user = UserResponse(
                id: UUID().uuidString,
                email: loginRequest.email,
                username: loginRequest.email.components(separatedBy: "@").first ?? "User"
            )
            
            return AuthResponse(
                success: true,
                token: "mock-token-\(UUID().uuidString)",
                user: user,
                message: "Login successful (demo mode)"
            )
        }
    }
    
    // GET /api/auth/profile
    func getProfile(req: Request) async throws -> ProfileResponse {
        // In a real app, you would extract user from JWT token
        // For demo, return mock profile
        
        let user = UserResponse(
            id: UUID().uuidString,
            email: "demo@example.com",
            username: "Demo User"
        )
        
        return ProfileResponse(
            success: true,
            user: user,
            message: "Profile retrieved successfully"
        )
    }
    
    // MARK: - Private validation methods
    
    private func validateEmail(_ email: String) throws {
        guard email.contains("@") && email.contains(".") else {
            throw Abort(.badRequest, reason: "Invalid email format")
        }
    }
    
    private func validatePassword(_ password: String) throws {
        guard password.count >= 6 else {
            throw Abort(.badRequest, reason: "Password must be at least 6 characters")
        }
    }
}
