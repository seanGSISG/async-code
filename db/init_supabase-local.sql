-- ====================
-- LOCAL DEVELOPMENT VERSION
-- ====================
-- This version includes a mock user for local development
-- with auth disabled. Use init_supabase.sql for production.
--
-- Mock User Credentials:
--   UUID: 00000000-0000-0000-0000-000000000000
--   Email: demo@localhost
--
-- To use this script:
--   1. Run this in your Supabase SQL Editor
--   2. Set NEXT_PUBLIC_DISABLE_AUTH=true in your .env
--   3. Start developing without authentication!
-- ====================

-- ====================
-- USERS TABLE
-- ====================

-- Create public.users table with auto-sync from auth.users
CREATE TABLE public.users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT,
  full_name TEXT,
  avatar_url TEXT,
  github_username TEXT,
  github_token TEXT, -- Encrypted github token for repository access
  preferences JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for users table
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Users can only view and edit their own profile
CREATE POLICY "Users can view own profile" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
  FOR UPDATE USING (auth.uid() = id);

-- Function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, avatar_url)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to handle user updates
CREATE OR REPLACE FUNCTION public.handle_user_update()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.users
  SET
    email = NEW.email,
    full_name = NEW.raw_user_meta_data->>'full_name',
    avatar_url = NEW.raw_user_meta_data->>'avatar_url',
    updated_at = NOW()
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Trigger for user updates
CREATE TRIGGER on_auth_user_updated
  AFTER UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_user_update();

-- ====================
-- PROJECTS TABLE
-- ====================

CREATE TABLE public.projects (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  
  -- GitHub repository information
  repo_url TEXT NOT NULL,
  repo_name TEXT NOT NULL,
  repo_owner TEXT NOT NULL,
  
  -- Project settings
  name TEXT NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  
  -- Custom settings (extensible)
  settings JSONB DEFAULT '{}',
  
  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  UNIQUE(user_id, repo_url)
);

-- Enable RLS for projects table
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

-- Users can only access their own projects
CREATE POLICY "Users can view own projects" ON public.projects
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own projects" ON public.projects
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own projects" ON public.projects
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own projects" ON public.projects
  FOR DELETE USING (auth.uid() = user_id);

-- Function to update projects updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for projects updated_at
CREATE TRIGGER update_projects_updated_at
  BEFORE UPDATE ON public.projects
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ====================
-- TASKS TABLE
-- ====================

CREATE TYPE task_status AS ENUM ('pending', 'running', 'completed', 'failed', 'cancelled');

CREATE TABLE public.tasks (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  project_id BIGINT REFERENCES public.projects(id) ON DELETE CASCADE,
  
  -- Task information
  status task_status DEFAULT 'pending',
  agent TEXT DEFAULT 'claude',
  
  -- GitHub/Repository information
  repo_url TEXT,
  target_branch TEXT DEFAULT 'main', -- The branch we're targeting (e.g., 'main')
  pr_branch TEXT, -- The branch we created for the PR (e.g., 'feature/optimize-readme')
  
  -- Container and execution details
  container_id TEXT,
  
  -- Git workflow tracking
  commit_hash TEXT, -- Final commit hash
  pr_number INTEGER, -- Pull request number
  pr_url TEXT, -- Full PR URL
  
  -- Results and patches
  git_diff TEXT,
  git_patch TEXT,
  changed_files JSONB DEFAULT '[]',
  
  -- Error handling
  error TEXT,
  
  -- AI Chat Messages (stored as JSONB array)
  chat_messages JSONB DEFAULT '[]', -- Array of {role, content, timestamp} objects
  
  -- Execution metadata
  execution_metadata JSONB DEFAULT '{}', -- Store execution logs, timing, etc.
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  started_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE
);

-- Enable RLS for tasks table
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

-- Users can only access their own tasks
CREATE POLICY "Users can view own tasks" ON public.tasks
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own tasks" ON public.tasks
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own tasks" ON public.tasks
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own tasks" ON public.tasks
  FOR DELETE USING (auth.uid() = user_id);

-- Trigger for tasks updated_at
CREATE TRIGGER update_tasks_updated_at
  BEFORE UPDATE ON public.tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ====================
-- INDEXES
-- ====================

-- Essential indexes only
CREATE INDEX idx_projects_user_id ON public.projects(user_id);
CREATE INDEX idx_tasks_user_id ON public.tasks(user_id);
CREATE INDEX idx_tasks_project_id ON public.tasks(project_id);
CREATE INDEX idx_tasks_status ON public.tasks(status);

-- ====================
-- LOCAL DEVELOPMENT USER
-- ====================

-- Create mock user in auth.users for local development
-- This bypasses the need for real authentication
INSERT INTO auth.users (
  id,
  instance_id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  invited_at,
  confirmation_token,
  confirmation_sent_at,
  recovery_token,
  recovery_sent_at,
  email_change_token_new,
  email_change,
  email_change_sent_at,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_super_admin,
  created_at,
  updated_at,
  phone,
  phone_confirmed_at,
  phone_change,
  phone_change_token,
  phone_change_sent_at,
  email_change_token_current,
  email_change_confirm_status,
  banned_until,
  reauthentication_token,
  reauthentication_sent_at
)
VALUES (
  '00000000-0000-0000-0000-000000000000',  -- Fixed UUID for local dev
  '00000000-0000-0000-0000-000000000000',  -- Instance ID
  'authenticated',                          -- Audience
  'authenticated',                          -- Role
  'demo@localhost',                         -- Email
  '',                                       -- No password (empty)
  NOW(),                                    -- Email confirmed now
  NULL,                                     -- Not invited
  '',                                       -- No confirmation token needed
  NULL,                                     -- No confirmation sent
  '',                                       -- No recovery token
  NULL,                                     -- No recovery sent
  '',                                       -- No email change token
  '',                                       -- No email change
  NULL,                                     -- No email change sent
  NOW(),                                    -- Last sign in now
  '{"provider":"email","providers":["email"]}',  -- App metadata
  '{"full_name":"Local Dev User"}',        -- User metadata
  FALSE,                                    -- Not super admin
  NOW(),                                    -- Created now
  NOW(),                                    -- Updated now
  NULL,                                     -- No phone
  NULL,                                     -- Phone not confirmed
  '',                                       -- No phone change
  '',                                       -- No phone change token
  NULL,                                     -- No phone change sent
  '',                                       -- No current email change token
  0,                                        -- Email change confirm status
  NULL,                                     -- Not banned
  '',                                       -- No reauth token
  NULL                                      -- No reauth sent
)
ON CONFLICT (id) DO NOTHING;

-- The trigger will automatically create the entry in public.users
-- But we can also insert directly to ensure it exists
INSERT INTO public.users (id, email, full_name, created_at, updated_at)
VALUES (
  '00000000-0000-0000-0000-000000000000',
  'demo@localhost',
  'Local Dev User',
  NOW(),
  NOW()
)
ON CONFLICT (id) DO UPDATE SET
  email = EXCLUDED.email,
  full_name = EXCLUDED.full_name,
  updated_at = NOW();

-- Database setup complete!
-- Mock user created: demo@localhost (00000000-0000-0000-0000-000000000000)
