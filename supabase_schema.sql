-- ════════════════════════════════════════════════════════
-- Supabase SQL Schema
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor)
-- ════════════════════════════════════════════════════════

-- 1. Profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  display_name TEXT,
  pair_id UUID,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Pairs table
CREATE TABLE IF NOT EXISTS pairs (
  id UUID PRIMARY KEY,
  user1_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user2_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  invite_code TEXT UNIQUE NOT NULL,
  mood1 TEXT,
  mood2 TEXT,
  miss_you_count INT DEFAULT 0,
  lamp_color1 TEXT,
  lamp_color2 TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Diary entries table
CREATE TABLE IF NOT EXISTS diary_entries (
  id UUID PRIMARY KEY,
  pair_id UUID NOT NULL REFERENCES pairs(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. Time capsules table
CREATE TABLE IF NOT EXISTS time_capsules (
  id UUID PRIMARY KEY,
  pair_id UUID NOT NULL REFERENCES pairs(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  unlock_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 5. Increment miss_you_count RPC function
CREATE OR REPLACE FUNCTION increment_miss_you(pair_row_id UUID)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
  new_count INT;
BEGIN
  UPDATE pairs
  SET miss_you_count = miss_you_count + 1
  WHERE id = pair_row_id
  RETURNING miss_you_count INTO new_count;
  RETURN new_count;
END;
$$;

-- ════════════════════════════════════════════════════════
-- Row Level Security (RLS) Policies
-- ════════════════════════════════════════════════════════

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE pairs ENABLE ROW LEVEL SECURITY;
ALTER TABLE diary_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE time_capsules ENABLE ROW LEVEL SECURITY;

-- Profiles: users can read/update their own profile
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Pairs: users in a pair can view/update it
CREATE POLICY "Pair members can view pair"
  ON pairs FOR SELECT
  USING (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "Authenticated users can create pairs"
  ON pairs FOR INSERT
  WITH CHECK (auth.uid() = user1_id);

CREATE POLICY "Pair members can update pair"
  ON pairs FOR UPDATE
  USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Allow joining a pair by invite code (user2_id is null means open)
CREATE POLICY "Anyone can view unpaired pairs by invite code"
  ON pairs FOR SELECT
  USING (user2_id IS NULL);

CREATE POLICY "Anyone can join an open pair"
  ON pairs FOR UPDATE
  USING (user2_id IS NULL);

-- Diary entries: pair members can CRUD
CREATE POLICY "Pair members can view diary"
  ON diary_entries FOR SELECT
  USING (
    pair_id IN (
      SELECT id FROM pairs
      WHERE user1_id = auth.uid() OR user2_id = auth.uid()
    )
  );

CREATE POLICY "Pair members can insert diary"
  ON diary_entries FOR INSERT
  WITH CHECK (
    pair_id IN (
      SELECT id FROM pairs
      WHERE user1_id = auth.uid() OR user2_id = auth.uid()
    )
  );

-- Time capsules: pair members can CRUD
CREATE POLICY "Pair members can view capsules"
  ON time_capsules FOR SELECT
  USING (
    pair_id IN (
      SELECT id FROM pairs
      WHERE user1_id = auth.uid() OR user2_id = auth.uid()
    )
  );

CREATE POLICY "Pair members can insert capsules"
  ON time_capsules FOR INSERT
  WITH CHECK (
    pair_id IN (
      SELECT id FROM pairs
      WHERE user1_id = auth.uid() OR user2_id = auth.uid()
    )
  );

-- ════════════════════════════════════════════════════════
-- Enable Realtime on pairs table
-- ════════════════════════════════════════════════════════
ALTER PUBLICATION supabase_realtime ADD TABLE pairs;
