-- ====================
-- FIX RLS POLICIES FOR LOCAL DEVELOPMENT
-- ====================
-- This script updates the RLS policies to allow the mock user
-- to be accessed when authentication is disabled.
--
-- Run this if you already have the database initialized but
-- are getting "Failed to save settings" errors.
-- ====================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;

-- Recreate with mock user support
CREATE POLICY "Users can view own profile" ON public.users
  FOR SELECT USING (
    auth.uid() = id OR
    id = '00000000-0000-0000-0000-000000000000'::uuid
  );

CREATE POLICY "Users can update own profile" ON public.users
  FOR UPDATE USING (
    auth.uid() = id OR
    id = '00000000-0000-0000-0000-000000000000'::uuid
  );

-- Verify the policies were created
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'users' AND schemaname = 'public';
