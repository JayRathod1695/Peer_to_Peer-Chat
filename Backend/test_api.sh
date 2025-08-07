#!/bin/bash

# API Test Script for Chat Backend with Python Integration

BASE_URL="http://localhost:8080"
PYTHON_DIR="./python"

echo "🧪 Testing Chat Backend API with Python Integration"
echo "=========================================="

# Test Python integration first
echo "🐍 Testing Python Supabase client..."
cd $PYTHON_DIR

echo "Testing login function..."
python3 supabase_client.py login test@example.com password123

echo ""
echo "Testing signup function..."
python3 supabase_client.py signup demo@example.com password123 demouser

echo ""
echo "Testing save_message function..."
python3 supabase_client.py save_message device1 local_device device1 "Hello from Python!"

echo ""
echo "Testing get_usage function..."
python3 supabase_client.py get_usage local_device

cd ..

echo ""
echo "✅ Python integration tests completed"
echo ""

# Test if server is running
echo "🏃 Testing server status..."
if ! curl -s "$BASE_URL" > /dev/null; then
    echo "❌ Server is not running! Please start it first with ./run.sh"
    exit 1
fi
echo "✅ Server is running"
echo ""

# Test signup
echo "👤 Testing user signup..."
SIGNUP_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/signup" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "username": "TestUser"
  }')
echo "Response: $SIGNUP_RESPONSE"
echo ""

# Test login
echo "🔐 Testing user login..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }')
echo "Response: $LOGIN_RESPONSE"
echo ""

# Extract token (basic extraction for demo)
TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

# Test profile (if we have a token)
if [ ! -z "$TOKEN" ]; then
    echo "👤 Testing user profile..."
    PROFILE_RESPONSE=$(curl -s "$BASE_URL/api/auth/profile" \
      -H "Authorization: Bearer $TOKEN")
    echo "Response: $PROFILE_RESPONSE"
    echo ""
fi

# Test scan
echo "📡 Testing device scan..."
SCAN_RESPONSE=$(curl -s "$BASE_URL/api/chat/scan")
echo "Response: $SCAN_RESPONSE"
echo ""

# Test connect
echo "🔗 Testing device connection..."
CONNECT_RESPONSE=$(curl -s -X POST "$BASE_URL/api/chat/connect/Device1")
echo "Response: $CONNECT_RESPONSE"
echo ""

# Test send message
echo "💬 Testing send message..."
MESSAGE_RESPONSE=$(curl -s -X POST "$BASE_URL/api/chat/sendMessage/Device1" \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello from test script!", "messageType": "text"}')
echo "Response: $MESSAGE_RESPONSE"
echo ""

# Test usage stats
echo "📊 Testing usage statistics..."
USAGE_RESPONSE=$(curl -s "$BASE_URL/api/chat/usage")
echo "Response: $USAGE_RESPONSE"
echo ""

# Test conversations
echo "💭 Testing conversations..."
CONVERSATIONS_RESPONSE=$(curl -s "$BASE_URL/api/chat/conversations")
echo "Response: $CONVERSATIONS_RESPONSE"
echo ""

# Test messages
echo "📨 Testing message history..."
MESSAGES_RESPONSE=$(curl -s "$BASE_URL/api/chat/messages/Device1")
echo "Response: $MESSAGES_RESPONSE"
echo ""

echo "✅ All API tests completed!"
echo "=========================================="
echo ""
echo "💡 Tips:"
echo "- For full Bluetooth functionality, run on a real iOS/macOS device"
echo "- Set up your Supabase project for full data persistence"
echo "- Check the README.md for complete setup instructions"
