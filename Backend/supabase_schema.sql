-- Supabase Database Schema for Chat Backend
-- Run these commands in your Supabase SQL editor

-- Enable Row Level Security
ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

-- Users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT NOT NULL,
  username TEXT NOT NULL,
  device_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Messages table
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  device_id TEXT NOT NULL,
  sender_id TEXT NOT NULL,
  receiver_id TEXT NOT NULL,
  text TEXT NOT NULL,
  message_type TEXT DEFAULT 'text',
  status TEXT DEFAULT 'sent',
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Connection logs table
CREATE TABLE IF NOT EXISTS public.connection_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  local_device_id TEXT NOT NULL,
  remote_device_id TEXT NOT NULL,
  status TEXT NOT NULL,
  error_message TEXT,
  duration REAL,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS messages_sender_idx ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS messages_receiver_idx ON public.messages(receiver_id);
CREATE INDEX IF NOT EXISTS messages_timestamp_idx ON public.messages(timestamp DESC);
CREATE INDEX IF NOT EXISTS connection_logs_local_device_idx ON public.connection_logs(local_device_id);
CREATE INDEX IF NOT EXISTS connection_logs_timestamp_idx ON public.connection_logs(timestamp DESC);

-- Row Level Security Policies
-- Users can only access their own data
CREATE POLICY "Users can view own profile" ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);

-- Messages policies (allow users to see messages they sent or received)
CREATE POLICY "Users can view their messages" ON public.messages FOR SELECT 
  USING (sender_id = auth.uid()::text OR receiver_id = auth.uid()::text);
CREATE POLICY "Users can insert messages" ON public.messages FOR INSERT 
  WITH CHECK (sender_id = auth.uid()::text);
CREATE POLICY "Users can update their sent messages" ON public.messages FOR UPDATE 
  USING (sender_id = auth.uid()::text);

-- Connection logs policies  
CREATE POLICY "Users can view their connection logs" ON public.connection_logs FOR SELECT
  USING (local_device_id = auth.uid()::text);
CREATE POLICY "Users can insert connection logs" ON public.connection_logs FOR INSERT
  WITH CHECK (local_device_id = auth.uid()::text);

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.connection_logs ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT ALL ON public.users TO authenticated;
GRANT ALL ON public.messages TO authenticated;
GRANT ALL ON public.connection_logs TO authenticated;

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update the updated_at column
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
