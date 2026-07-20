-- Takip (follows) tablosu — kullanıcı profil sayfası takipçi/takip grafiği.
-- Daha önce docs/supabase/follows_migration.sql'de manuel adımdı; migration'a alındı.
CREATE TABLE IF NOT EXISTS follows (
  follower_id  uuid REFERENCES auth.users NOT NULL,
  following_id uuid REFERENCES auth.users NOT NULL,
  created_at   timestamptz DEFAULT now(),
  PRIMARY KEY (follower_id, following_id)
);

ALTER TABLE follows ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Herkes okuyabilir" ON follows;
CREATE POLICY "Herkes okuyabilir" ON follows
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Kendi takibini yönetir" ON follows;
CREATE POLICY "Kendi takibini yönetir" ON follows
  FOR ALL USING (auth.uid() = follower_id);
