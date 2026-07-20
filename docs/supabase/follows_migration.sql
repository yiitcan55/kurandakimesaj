-- Supabase Dashboard > SQL Editor'de çalıştır
CREATE TABLE IF NOT EXISTS follows (
  follower_id  uuid REFERENCES auth.users NOT NULL,
  following_id uuid REFERENCES auth.users NOT NULL,
  created_at   timestamptz DEFAULT now(),
  PRIMARY KEY (follower_id, following_id)
);

ALTER TABLE follows ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Herkes okuyabilir" ON follows
  FOR SELECT USING (true);

CREATE POLICY "Kendi takibini yönetir" ON follows
  FOR ALL USING (auth.uid() = follower_id);
