-- ================================================================
-- SMART GOVERNANCE — BROADCAST & REALTIME NOTIFICATION UPGRADE
-- Run this ONCE in the Supabase SQL Editor.
-- Uses ALTER TABLE — safe on existing data. No data loss.
-- ================================================================

-- ── 1. ALTER announcements TABLE ─────────────────────────────────
ALTER TABLE public.announcements
  ADD COLUMN IF NOT EXISTS image_url   TEXT,
  ADD COLUMN IF NOT EXISTS voice_url   TEXT,
  ADD COLUMN IF NOT EXISTS updated_at  TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS sender_role TEXT,
  -- Future-proof targeting: target_type = 'role'|'ward'|'village'|'all'
  ADD COLUMN IF NOT EXISTS target_type TEXT DEFAULT 'role',
  ADD COLUMN IF NOT EXISTS target_id   TEXT; -- role string, ward_id, village_id, or NULL for 'all'

-- Backfill sender_role from the existing created_by_role column
UPDATE public.announcements
   SET sender_role = created_by_role
 WHERE sender_role IS NULL;

-- Backfill target_type / target_id from existing target_audience strings
UPDATE public.announcements
   SET target_type = CASE
         WHEN target_audience IN ('All Users', 'All') THEN 'all'
         ELSE 'role'
       END,
       target_id = CASE
         WHEN target_audience IN ('All Users', 'All') THEN NULL
         WHEN target_audience = 'Citizens'            THEN 'citizen'
         WHEN target_audience = 'Ward Members'        THEN 'wardAdmin'
         WHEN target_audience = 'Category Officers'   THEN 'categoryOfficer'
         WHEN target_audience = 'Mandal Officers'     THEN 'mandalOfficer'
         ELSE target_audience
       END
 WHERE target_type IS NULL OR target_id IS NULL;

-- ── 2. ALTER notifications TABLE ─────────────────────────────────
ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS announcement_id  TEXT REFERENCES public.announcements(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS receiver_role    TEXT,
  ADD COLUMN IF NOT EXISTS read_at          TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS notification_type TEXT;

-- Backfill notification_type from existing type column
UPDATE public.notifications
   SET notification_type = type
 WHERE notification_type IS NULL AND type IS NOT NULL;

-- ── 3. PERFORMANCE INDEXES ───────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_notif_user_id
  ON public.notifications("userId");

CREATE INDEX IF NOT EXISTS idx_notif_announcement_id
  ON public.notifications(announcement_id);

CREATE INDEX IF NOT EXISTS idx_notif_is_read
  ON public.notifications("isRead");

CREATE INDEX IF NOT EXISTS idx_notif_created_at
  ON public.notifications("createdAt" DESC);

CREATE INDEX IF NOT EXISTS idx_notif_user_unread
  ON public.notifications("userId", "isRead")
  WHERE "isRead" = FALSE;

CREATE INDEX IF NOT EXISTS idx_ann_created_by
  ON public.announcements(created_by_id);

CREATE INDEX IF NOT EXISTS idx_ann_target
  ON public.announcements(target_type, target_id);

CREATE INDEX IF NOT EXISTS idx_ann_created_at
  ON public.announcements(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_ann_reads_lookup
  ON public.announcement_reads(announcement_id, user_id);

CREATE INDEX IF NOT EXISTS idx_ann_reads_user
  ON public.announcement_reads(user_id);

-- ── 4. BROADCAST STATISTICS VIEW ─────────────────────────────────
-- Used by Broadcast History screen — avoids Flutter-side aggregation
CREATE OR REPLACE VIEW public.v_broadcast_stats AS
SELECT
  a.id                                                        AS announcement_id,
  a.title,
  a.message,
  a.created_by_id                                             AS sender_id,
  a.created_by_name                                           AS sender_name,
  COALESCE(a.sender_role, a.created_by_role)                  AS sender_role,
  a.target_audience,
  a.target_type,
  a.target_id,
  a.image_url,
  a.voice_url,
  a.attachment_url,
  a.created_at,
  a.updated_at,
  COUNT(n.id)                                                 AS total_delivered,
  COUNT(n.id) FILTER (WHERE n."isRead" = TRUE)                AS read_count,
  COUNT(n.id) FILTER (WHERE n."isRead" = FALSE)               AS unread_count,
  CASE
    WHEN COUNT(n.id) = 0 THEN 0.0
    ELSE ROUND(
           COUNT(n.id) FILTER (WHERE n."isRead" = TRUE) * 100.0
           / COUNT(n.id),
           1
         )
  END                                                         AS read_percentage
FROM public.announcements a
LEFT JOIN public.notifications n
  ON  n.announcement_id = a.id
  AND n.notification_type = 'announcement'
GROUP BY
  a.id, a.title, a.message,
  a.created_by_id, a.created_by_name,
  a.sender_role, a.created_by_role,
  a.target_audience, a.target_type, a.target_id,
  a.image_url, a.voice_url, a.attachment_url,
  a.created_at, a.updated_at;

-- ── 5. FUNCTION: Auto-create notifications when announcement is inserted ──
CREATE OR REPLACE FUNCTION public.auto_create_announcement_notifications()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_target_roles TEXT[];
  v_inserted_count INT;
BEGIN
  -- Resolve which user roles should receive this announcement
  IF NEW.target_type = 'all' THEN
    v_target_roles := ARRAY['citizen','wardAdmin','categoryOfficer','mandalOfficer'];

  ELSIF NEW.target_type = 'role' AND NEW.target_id IS NOT NULL THEN
    v_target_roles := ARRAY[NEW.target_id];

  ELSE
    -- Backward-compat: map legacy target_audience strings
    v_target_roles := CASE NEW.target_audience
      WHEN 'Citizens'          THEN ARRAY['citizen']
      WHEN 'Ward Members'      THEN ARRAY['wardAdmin']
      WHEN 'Category Officers' THEN ARRAY['categoryOfficer']
      WHEN 'Mandal Officers'   THEN ARRAY['mandalOfficer']
      WHEN 'All Users'         THEN ARRAY['citizen','wardAdmin','categoryOfficer','mandalOfficer']
      WHEN 'All'               THEN ARRAY['citizen','wardAdmin','categoryOfficer','mandalOfficer']
      ELSE                          ARRAY[]::TEXT[]
    END;
  END IF;

  -- Bulk INSERT one notification per eligible user (excluding sender)
  INSERT INTO public.notifications (
    id,
    "userId",
    title,
    body,
    "createdAt",
    "isRead",
    type,
    notification_type,
    announcement_id,
    receiver_role
  )
  SELECT
    'annnotif_' || NEW.id || '_' || u.id,
    u.id,
    NEW.title,
    LEFT(NEW.message, 200),
    NOW(),
    FALSE,
    'announcement',
    'announcement',
    NEW.id,
    u.role
  FROM public.users u
  WHERE u.role = ANY(v_target_roles)
    AND u.id <> NEW.created_by_id;

  -- Atomically update total_sent on the announcement
  GET DIAGNOSTICS v_inserted_count = ROW_COUNT;

  UPDATE public.announcements
     SET total_sent = v_inserted_count,
         updated_at = NOW()
   WHERE id = NEW.id;

  RETURN NEW;
END;
$$;

-- ── 6. TRIGGER: Fire after each announcement INSERT ───────────────
DROP TRIGGER IF EXISTS trg_auto_announcement_notifications ON public.announcements;
CREATE TRIGGER trg_auto_announcement_notifications
  AFTER INSERT ON public.announcements
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_create_announcement_notifications();

-- ── 7. FUNCTION: Sync announcement_reads when notification is read ──
CREATE OR REPLACE FUNCTION public.sync_announcement_reads_on_read()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Only act when isRead flips FALSE → TRUE for an announcement notification
  IF NEW."isRead" = TRUE
     AND OLD."isRead" = FALSE
     AND NEW.announcement_id IS NOT NULL
  THEN
    INSERT INTO public.announcement_reads (id, announcement_id, user_id, read_at)
    VALUES (
      'read_' || NEW.announcement_id || '_' || NEW."userId",
      NEW.announcement_id,
      NEW."userId",
      COALESCE(NEW.read_at, NOW())
    )
    ON CONFLICT (id) DO UPDATE
      SET read_at = COALESCE(EXCLUDED.read_at, NOW());

    -- Stamp read_at on the notification row
    NEW.read_at := COALESCE(NEW.read_at, NOW());
  END IF;

  RETURN NEW;
END;
$$;

-- ── 8. TRIGGER: Fire on each notification UPDATE ──────────────────
DROP TRIGGER IF EXISTS trg_sync_announcement_reads ON public.notifications;
CREATE TRIGGER trg_sync_announcement_reads
  BEFORE UPDATE OF "isRead" ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_announcement_reads_on_read();

-- ── 9. RLS — Updated policies for announcements & notifications ───

-- Announcements: anon users can read all, insert their own
DROP POLICY IF EXISTS "Enable read/write for anonymous users on announcements" ON public.announcements;
CREATE POLICY "announcements_open_access" ON public.announcements
  FOR ALL USING (true) WITH CHECK (true);

-- Notifications: anon users can read all (app filters by userId in Flutter)
DROP POLICY IF EXISTS "Enable read/write for anonymous users on notifications" ON public.notifications;
CREATE POLICY "notifications_open_access" ON public.notifications
  FOR ALL USING (true) WITH CHECK (true);

-- announcement_reads: open (existing policy kept)
DROP POLICY IF EXISTS "Enable read/write for anonymous users on announcement_reads" ON public.announcement_reads;
CREATE POLICY "announcement_reads_open_access" ON public.announcement_reads
  FOR ALL USING (true) WITH CHECK (true);

-- ── 10. ENABLE REALTIME for new tables ───────────────────────────
-- notifications was missing from publication — add it now
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.announcement_reads;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
END;
$$;

-- ── 11. STORAGE BUCKET: government-files ─────────────────────────
INSERT INTO storage.buckets (id, name, public)
VALUES ('government-files', 'government-files', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for government-files bucket
DROP POLICY IF EXISTS "gov_files_select" ON storage.objects;
DROP POLICY IF EXISTS "gov_files_insert" ON storage.objects;
DROP POLICY IF EXISTS "gov_files_update" ON storage.objects;
DROP POLICY IF EXISTS "gov_files_delete" ON storage.objects;

CREATE POLICY "gov_files_select" ON storage.objects
  FOR SELECT USING (bucket_id = 'government-files');

CREATE POLICY "gov_files_insert" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'government-files');

CREATE POLICY "gov_files_update" ON storage.objects
  FOR UPDATE USING (bucket_id = 'government-files');

CREATE POLICY "gov_files_delete" ON storage.objects
  FOR DELETE USING (bucket_id = 'government-files');

-- ── DONE ─────────────────────────────────────────────────────────
-- Run in Supabase SQL Editor. All changes are additive and safe.
