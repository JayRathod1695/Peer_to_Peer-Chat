#!/usr/bin/env python3
"""
Dummy data for testing the chat backend
"""

from datetime import datetime, timedelta

# Dummy devices for Bluetooth scanning
dummy_devices = [
    "Device 1",
    "Device 2", 
    "Device 3",
    "iPhone 12",
    "MacBook Pro",
    "iPad Air",
    "John's iPhone",
    "Sarah's MacBook"
]

# Dummy connection statistics
dummy_stats = {
    "attempts": 15,
    "successes": 12,
    "failures": 3
}

# Dummy message previews
dummy_previews = [
    {
        "deviceId": "Device 1",
        "preview": "Hey there! How are you doing?",
        "timestamp": (datetime.now() - timedelta(hours=1)).isoformat(),
        "unreadCount": 2
    },
    {
        "deviceId": "Device 2", 
        "preview": "Thanks for the file you sent earlier",
        "timestamp": (datetime.now() - timedelta(hours=2)).isoformat(),
        "unreadCount": 0
    },
    {
        "deviceId": "iPhone 12",
        "preview": "Are we still meeting tomorrow?",
        "timestamp": (datetime.now() - timedelta(days=1)).isoformat(),
        "unreadCount": 1
    },
    {
        "deviceId": "MacBook Pro",
        "preview": "The project looks great! 👍",
        "timestamp": (datetime.now() - timedelta(days=2)).isoformat(),
        "unreadCount": 0
    },
    {
        "deviceId": "John's iPhone",
        "preview": "Let's sync up later this week",
        "timestamp": (datetime.now() - timedelta(hours=6)).isoformat(),
        "unreadCount": 3
    }
]

# Dummy messages for conversation history
dummy_messages = {
    "Device 1": [
        {
            "id": "msg_1",
            "sender_id": "local_device",
            "receiver_id": "Device 1",
            "text": "Hello! How's it going?",
            "timestamp": (datetime.now() - timedelta(hours=2)).isoformat(),
            "status": "delivered"
        },
        {
            "id": "msg_2",
            "sender_id": "Device 1",
            "receiver_id": "local_device", 
            "text": "Hey there! All good, thanks for asking!",
            "timestamp": (datetime.now() - timedelta(hours=2, minutes=5)).isoformat(),
            "status": "delivered"
        },
        {
            "id": "msg_3",
            "sender_id": "local_device",
            "receiver_id": "Device 1",
            "text": "Great to hear! Want to catch up later?",
            "timestamp": (datetime.now() - timedelta(hours=1, minutes=30)).isoformat(),
            "status": "delivered"
        }
    ],
    "iPhone 12": [
        {
            "id": "msg_4",
            "sender_id": "iPhone 12",
            "receiver_id": "local_device",
            "text": "Are we still meeting tomorrow?",
            "timestamp": (datetime.now() - timedelta(days=1)).isoformat(),
            "status": "delivered"
        },
        {
            "id": "msg_5", 
            "sender_id": "local_device",
            "receiver_id": "iPhone 12",
            "text": "Yes, let's meet at 3 PM",
            "timestamp": (datetime.now() - timedelta(hours=20)).isoformat(),
            "status": "sent"
        }
    ]
}

# Dummy user data
dummy_users = [
    {
        "id": "user_1",
        "email": "test@example.com",
        "username": "testuser",
        "device_id": "local_device"
    },
    {
        "id": "user_2", 
        "email": "demo@example.com",
        "username": "demouser",
        "device_id": "demo_device"
    }
]

# Dummy connection logs
dummy_connection_logs = [
    {
        "id": "log_1",
        "local_device_id": "local_device",
        "remote_device_id": "Device 1",
        "status": "success",
        "timestamp": (datetime.now() - timedelta(hours=3)).isoformat(),
        "duration": 45.2
    },
    {
        "id": "log_2",
        "local_device_id": "local_device", 
        "remote_device_id": "iPhone 12",
        "status": "attempt",
        "timestamp": (datetime.now() - timedelta(hours=1)).isoformat()
    },
    {
        "id": "log_3",
        "local_device_id": "local_device",
        "remote_device_id": "MacBook Pro", 
        "status": "failure",
        "timestamp": (datetime.now() - timedelta(minutes=30)).isoformat(),
        "error_message": "Device not responding"
    }
]

def get_dummy_data(data_type: str):
    """
    Get dummy data by type
    """
    data_map = {
        "devices": dummy_devices,
        "stats": dummy_stats, 
        "previews": dummy_previews,
        "messages": dummy_messages,
        "users": dummy_users,
        "connection_logs": dummy_connection_logs
    }
    return data_map.get(data_type, [])
