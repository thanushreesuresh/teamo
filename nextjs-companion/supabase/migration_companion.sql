-- ─── AI Companion Mode — Supabase Migration ─────────────────────────────────
-- Run this in your Supabase SQL Editor

-- 1. Add last_active timestamp to profiles
--    Updated whenever the user performs any action in the app
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS last_active TIMESTAMPTZ DEFAULT NOW();

-- Auto-update last_active on any profile row update
CREATE OR REPLACE FUNCTION update_last_active()
RETURNS TRIGGER AS $$
BEGIN
  NEW.last_active = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_last_active ON profiles;
CREATE TRIGGER trg_update_last_active
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_last_active();

-- 2. Add style_summary JSONB column to profiles
--    Populated by your style analysis logic (e.g. after 10+ diary entries)
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS style_summary JSONB DEFAULT NULL;

-- Example update (run manually or from app logic):
-- UPDATE profiles
-- SET style_summary = '{"avg_length":"medium","emoji_usage":"low","tone":"calm","response_speed":"fast"}'
-- WHERE id = '<user-uuid>';

-- 3. Index for fast partner lookup by last_active
CREATE INDEX IF NOT EXISTS idx_profiles_last_active
  ON profiles (last_active DESC);

-- 4. RLS: users can only read their own or their partner's style_summary/last_active
-- (Add to your existing RLS policies if needed)
-- The anon key already respects row-level security;
-- ensure your profiles policy allows SELECT for paired users.
