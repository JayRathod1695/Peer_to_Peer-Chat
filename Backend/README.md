# Chat Backend - Swift + Python Integration

A complete backend for an offline peer-to-peer chat application using **Swift with Vapor** for the REST API and Core Bluetooth, combined with **Python for Supabase** authentication and CRUD operations. The backend supports iOS-macOS and macOS-macOS connections via Core Bluetooth.

## Architecture Overview

- **Swift (Vapor)**: REST API and Core Bluetooth for peer-to-peer communication
- **Python**: Supabase integration for authentication and data persistence  
- **Frontend Integration**: Next.js frontend communicates only through the Vapor REST API
- **Local Development**: No Docker - everything runs locally for simplicity

## Features

- **Bluetooth Communication**: Discover, connect, and message nearby devices using Core Bluetooth
- **REST API**: Comprehensive endpoints for scanning, connecting, messaging, and usage statistics
- **Supabase Integration**: User authentication and data persistence via Python client
- **Dual Data Storage**: Local SQLite + Supabase for redundancy and offline capability
- **Mock Data Support**: Built-in dummy data for testing and demos

## Project Structure

```
backend/
├── Sources/App/                    # Swift/Vapor Application
│   ├── Controllers/                # API route handlers
│   │   ├── ChatController.swift    # Chat endpoints (scan, connect, message)
│   │   └── AuthController.swift    # Authentication endpoints  
│   ├── Models/                    # Data models
│   │   ├── User.swift             # User model and migrations
│   │   ├── Message.swift          # Message model and migrations
│   │   └── ConnectionLog.swift    # Connection log model and migrations
│   ├── Services/                  # Core business logic
│   │   ├── BluetoothService.swift # Core Bluetooth operations
│   │   ├── DatabaseService.swift  # Local database CRUD operations
│   │   └── PythonBridge.swift     # Swift-Python integration bridge
│   ├── Configurations/            # Application setup
│   │   └── configure.swift        # Vapor configuration
│   ├── main.swift                 # Application entry point
│   └── routes.swift               # API route definitions
├── python/                        # Python/Supabase Integration
│   ├── supabase_client.py         # Supabase auth and CRUD operations
│   ├── dummy_data.py              # Test and demo data
│   └── requirements.txt           # Python dependencies
├── Tests/                         # Test files
├── Package.swift                  # Swift package configuration
├── setup.sh                      # Setup script
├── run.sh                        # Development server script
├── test_api.sh                   # API testing script
└── README.md                     # This file
```

## API Endpoints

### Chat Endpoints

- `GET /api/chat/scan` - Scan for nearby Bluetooth devices
- `POST /api/chat/connect/:deviceId` - Connect to a specific device
- `POST /api/chat/sendMessage/:deviceId` - Send a message to a connected device
- `GET /api/chat/usage` - Get usage statistics and message previews
- `GET /api/chat/messages/:deviceId` - Get message history with a specific device
- `GET /api/chat/conversations` - Get all conversation previews

### Authentication Endpoints

- `POST /api/auth/signup` - Create a new user account
- `POST /api/auth/login` - Login with email and password
- `GET /api/auth/profile` - Get user profile (requires authentication)

## Setup and Installation

### Prerequisites

- Xcode 14+ (for Swift 5.7+)
- Swift 5.7+
- macOS 12+ or iOS 15+

## Quick Start

### Prerequisites

- **Swift 5.7+** and Xcode 14+ (for macOS development)
- **Python 3.8+** with pip
- **macOS 12+** or **iOS 15+** for Bluetooth functionality
- **Supabase account** (optional - works with mock data)

### Installation

1. **Clone or navigate to the project directory**
   ```bash
   cd /path/to/your/project/Backend
   ```

2. **Run the setup script**
   ```bash
   ./setup.sh
   ```
   
   This will:
   - Create a Python virtual environment
   - Install Python dependencies
   - Make scripts executable
   - Test the Python integration

3. **Set up Supabase (Optional)**
   ```bash
   # Copy environment template
   cp .env.example .env
   
   # Edit .env with your Supabase credentials
   # SUPABASE_URL=https://your-project.supabase.co
   # SUPABASE_KEY=your-anon-key
   ```

4. **Start the server**
   ```bash
   ./run.sh
   ```

5. **Test the API**
   ```bash
   ./test_api.sh
   ```

The server will start on `http://localhost:8080`

### Manual Setup (Alternative)

If the setup script doesn't work, you can set up manually:

```bash
# Install Python dependencies
cd python
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
cd ..

# Build Swift project
swift build

# Run the server
swift run
```

### Dependencies

#### Swift Dependencies (Package.swift)
- **Vapor 4.89.0+** - Swift web framework
- **Fluent 4.8.0+** - ORM for database operations
- **FluentSQLiteDriver 4.0.0+** - SQLite database driver

#### Python Dependencies (python/requirements.txt)
- **supabase 2.3.4** - Supabase Python client
- **python-dotenv 1.0.0** - Environment variable management

## Swift-Python Integration

The backend uses a unique architecture where Swift handles the API and Bluetooth communication, while Python manages Supabase operations. This integration happens through the `PythonBridge.swift` service.

### How It Works

1. **Swift API receives requests** from the frontend
2. **PythonBridge calls Python scripts** using subprocess
3. **Python scripts interact with Supabase** for auth and data operations
4. **Results flow back** through the bridge to the API response

### Key Benefits

- **Separation of Concerns**: Swift for system-level operations, Python for cloud integration
- **Flexibility**: Easy to replace Supabase with other services
- **Development Speed**: Leverage both ecosystems' strengths
- **Fallback Support**: Mock data when Python/Supabase unavailable

## Bluetooth Configuration

### Service and Characteristic UUIDs

- **Chat Service UUID**: `12345678-1234-1234-1234-1234567890AB`
- **Message Characteristic UUID**: `12345678-1234-1234-1234-1234567890AC`

### Permissions

For Bluetooth functionality, add the following to your `Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to communicate with nearby devices for peer-to-peer chat.</string>
```

## Database Schema

### Users Table
- `id` (UUID, Primary Key)
- `username` (String)
- `email` (String, Unique)
- `password_hash` (String)
- `device_id` (String)
- `created_at` (DateTime)
- `updated_at` (DateTime)

### Messages Table
- `id` (UUID, Primary Key)
- `content` (String)
- `sender_device_id` (String)
- `receiver_device_id` (String)
- `message_type` (Enum: text, image, file)
- `delivery_status` (Enum: pending, sent, delivered, failed)
- `created_at` (DateTime)
- `updated_at` (DateTime)

### Connection Logs Table
- `id` (UUID, Primary Key)
- `local_device_id` (String)
- `remote_device_id` (String)
- `connection_type` (Enum: incoming, outgoing)
- `status` (Enum: attempt, success, failure, disconnected)
- `error_message` (String, Optional)
- `duration` (Double, Optional)
- `created_at` (DateTime)
- `updated_at` (DateTime)

## API Usage Examples

### Scanning for Devices

```bash
curl http://localhost:8080/api/chat/scan
```

Response:
```json
{
  "status": "scanning",
  "devices": ["Device 1", "Device 2", "iPhone 12"],
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

### Connecting to a Device

```bash
curl -X POST http://localhost:8080/api/chat/connect/Device1
```

Response:
```json
{
  "status": "connected",
  "deviceId": "Device1",
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

### Sending a Message

```bash
curl -X POST http://localhost:8080/api/chat/sendMessage/Device1 \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello there!"}'
```

Response:
```json
{
  "success": true,
  "message": "Hello there!",
  "messageId": "uuid-string",
  "deviceId": "Device1",
  "status": "sent",
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

### Getting Usage Statistics

```bash
curl http://localhost:8080/api/chat/usage
```

Response:
```json
{
  "stats": {
    "attempts": 15,
    "successes": 12,
    "failures": 3
  },
  "previews": [
    {
      "deviceId": "Device1",
      "preview": "Hey there! How are you doing?",
      "timestamp": "2024-01-01T11:00:00.000Z",
      "unreadCount": 2
    }
  ],
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

### User Registration

```bash
curl -X POST http://localhost:8080/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123",
    "username": "TestUser"
  }'
```

### User Login

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'
```

## Testing

### Run Tests
```bash
swift test
```

### Manual Testing with Postman or curl

The API includes dummy data for testing purposes, so you can test all endpoints even without real Bluetooth devices.

## Development Notes

### Dummy Data

The backend includes dummy data for testing and demo purposes:

- **Devices**: "Device 1", "Device 2", "Device 3", "iPhone 12", "MacBook Pro", "iPad Air"
- **Statistics**: 15 attempts, 12 successes, 3 failures
- **Message Previews**: Sample conversation previews with timestamps

### Bluetooth Implementation

- The `BluetoothService` class handles Core Bluetooth operations
- Scanning and advertising work with the custom service UUID
- Message sending/receiving uses characteristic read/write operations
- Connection state is tracked and logged to the database

### Error Handling

- API endpoints return appropriate HTTP status codes
- Errors are logged using Vapor's logging system
- Graceful fallback to dummy data when real operations fail

### Security Considerations

- Passwords are hashed using Bcrypt
- Basic token-based authentication (mock implementation for demo)
- Input validation for email formats and password requirements

## Deployment

For production deployment:

1. Configure environment-specific settings
2. Use a production-grade database (PostgreSQL recommended)
3. Implement proper JWT token authentication
4. Add HTTPS/TLS configuration
5. Set up proper logging and monitoring

## Troubleshooting

### Common Issues

1. **Bluetooth not working**: Ensure you're running on a real device, not simulator
2. **Database errors**: Check file permissions for SQLite database
3. **Build errors**: Ensure all dependencies are properly resolved

### Logging

The application uses structured logging. Check console output for detailed error messages and operation status.

## Contributing

1. Follow Swift coding conventions
2. Add tests for new functionality
3. Update documentation for API changes
4. Ensure Bluetooth features work on real devices

## License

This project is created for educational and demo purposes.
