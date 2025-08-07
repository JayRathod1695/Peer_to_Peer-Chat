#!/bin/bash

# Build and run script for the Chat Backend

set -e

echo "🚀 Building Chat Backend..."

# Check if Swift is installed
if ! command -v swift &> /dev/null
then
    echo "❌ Swift is not installed. Please install Swift or Xcode."
    exit 1
fi

echo "✅ Swift found"

# Build the project
echo "📦 Building project..."
swift build

if [ $? -eq 0 ]; then
    echo "✅ Build successful"
else
    echo "❌ Build failed"
    exit 1
fi

# Run the server
echo "🏃 Starting server on http://localhost:8080..."
echo "📱 Backend for offline peer-to-peer chat application"
echo "🔍 Available endpoints:"
echo "   GET    /api/chat/scan"
echo "   POST   /api/chat/connect/:deviceId"
echo "   POST   /api/chat/sendMessage/:deviceId"
echo "   GET    /api/chat/usage"
echo "   GET    /api/chat/messages/:deviceId"
echo "   GET    /api/chat/conversations"
echo "   POST   /api/auth/signup"
echo "   POST   /api/auth/login"
echo "   GET    /api/auth/profile"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

swift run
