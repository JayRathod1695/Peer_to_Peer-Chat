#!/bin/bash

# Setup script for the Chat Backend with Python integration

set -e

echo "🚀 Setting up Chat Backend with Python Integration..."

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null
then
    echo "❌ Python 3 is not installed. Please install Python 3.8+ first."
    exit 1
fi

echo "✅ Python 3 found"

# Check if pip is installed
if ! command -v pip3 &> /dev/null
then
    echo "❌ pip3 is not installed. Please install pip first."
    exit 1
fi

echo "✅ pip3 found"

# Create Python virtual environment (optional but recommended)
if [ ! -d "python/venv" ]; then
    echo "🐍 Creating Python virtual environment..."
    cd python
    python3 -m venv venv
    cd ..
    echo "✅ Virtual environment created"
fi

# Activate virtual environment and install dependencies
echo "📦 Installing Python dependencies..."
cd python

# Activate virtual environment if it exists
if [ -d "venv" ]; then
    source venv/bin/activate
    echo "✅ Virtual environment activated"
fi

# Install dependencies
pip3 install -r requirements.txt

echo "✅ Python dependencies installed"

# Go back to main directory
cd ..

# Check if Swift is installed
if ! command -v swift &> /dev/null
then
    echo "❌ Swift is not installed. Please install Swift or Xcode."
    exit 1
fi

echo "✅ Swift found"

# Make scripts executable
chmod +x run.sh
chmod +x test_api.sh
chmod +x python/supabase_client.py

echo "✅ Scripts made executable"

# Test Python integration
echo "🧪 Testing Python integration..."
cd python
python3 supabase_client.py login test@example.com password123
cd ..

echo "✅ Python integration test completed"

echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "📝 Next steps:"
echo "1. Set up your Supabase project:"
echo "   - Create a new project at https://supabase.com"
echo "   - Get your URL and anon key"
echo "   - Set environment variables:"
echo "     export SUPABASE_URL='https://your-project.supabase.co'"
echo "     export SUPABASE_KEY='your-anon-key'"
echo ""
echo "2. Create the following tables in your Supabase database:"
echo "   - users (id, email, username, token)"
echo "   - messages (id, device_id, sender_id, receiver_id, text, timestamp, status)"
echo "   - connection_logs (id, local_device_id, remote_device_id, status, timestamp, error_message)"
echo ""
echo "3. Start the server:"
echo "   ./run.sh"
echo ""
echo "4. Test the API:"
echo "   ./test_api.sh"
echo ""
echo "📱 For Bluetooth functionality, remember to:"
echo "- Run on a real iOS/macOS device (not simulator)"
echo "- Add NSBluetoothAlwaysUsageDescription to Info.plist"
echo "- Ensure Bluetooth is enabled"
