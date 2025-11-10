-- ====================
-- RESET SUPABASE DATABASE
-- ====================
-- This script drops all tables, functions, triggers, and types
-- Use this to clean your database before running init_supabase-local.sql
--
-- WARNING: This will DELETE ALL DATA. Use with caution!
-- ====================

-- Drop all RLS policies first (they depend on tables)
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Users can view own projects" ON public.projects;
DROP POLICY IF EXISTS "Users can insert own projects" ON public.projects;
DROP POLICY IF EXISTS "Users can update own projects" ON public.projects;
DROP POLICY IF EXISTS "Users can delete own projects" ON public.projects;
DROP POLICY IF EXISTS "Users can view own tasks" ON public.tasks;
DROP POLICY IF EXISTS "Users can insert own tasks" ON public.tasks;
DROP POLICY IF EXISTS "Users can update own tasks" ON public.tasks;
DROP POLICY IF EXISTS "Users can delete own tasks" ON public.tasks;

-- Drop triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;
DROP TRIGGER IF EXISTS update_projects_updated_at ON public.projects;
DROP TRIGGER IF EXISTS update_tasks_updated_at ON public.tasks;

-- Drop functions
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.handle_user_update() CASCADE;
DROP FUNCTION IF EXISTS public.update_updated_at_column() CASCADE;

-- Drop tables (order matters due to foreign keys)
DROP TABLE IF EXISTS public.tasks CASCADE;
DROP TABLE IF EXISTS public.projects CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- Drop custom types
DROP TYPE IF EXISTS task_status CASCADE;

-- Clean up any existing mock user from auth.users (if exists)
DELETE FROM auth.users WHERE id = '00000000-0000-0000-0000-000000000000';

-- Database reset complete!
-- Now you can run init_supabase-local.sql to set up fresh tables
