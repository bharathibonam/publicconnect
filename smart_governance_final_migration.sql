-- ================================================================
-- SMART GOVERNANCE — FINAL DATABASE MIGRATION
-- Combines Broadcast, Announcements, Notifications & Completed Works
-- Safe to run multiple times on existing database.
-- ================================================================

-- ── 1. ALTER announcements TABLE ─────────────────────────────────
ALTER TABLE public.announcements
  ADD COLUMN IF NOT EXISTS image_url   TEXT,
  ADD COLUMN IF NOT EXISTS voice_url   TEXT,
  ADD COLUMN IF NOT EXISTS pdf_url     TEXT,
  ADD COLUMN IF NOT EXISTS updated_at  TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS sender_role TEXT,
  ADD COLUMN IF NOT EXISTS sender_name TEXT,
  -- Future-proof targeting: target_type = 'role'|'ward'|'village'|'all'
  ADD COLUMN IF NOT EXISTS target_type TEXT DEFAULT 'role',
  ADD COLUMN IF NOT EXISTS target_id   TEXT; -- role string, ward_id, village_id, or NULL for 'all'

-- Backfill sender_role and sender_name from the existing columns
UPDATE public.announcements
   SET sender_role = created_by_role
 WHERE sender_role IS NULL;

UPDATE public.announcements
   SET sender_name = created_by_name
 WHERE sender_name IS NULL;

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

-- ── 3. CREATE completed_works TABLE ──────────────────────────────
CREATE TABLE IF NOT EXISTS public.completed_works (
    id TEXT PRIMARY KEY,
    complaint_id TEXT REFERENCES public.complaints(id) ON DELETE CASCADE,
    ward_member_id TEXT REFERENCES public.users(id) ON DELETE SET NULL,
    citizen_id TEXT REFERENCES public.users(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    before_image_url TEXT,
    after_image_url TEXT,
    video_url TEXT,
    voice_url TEXT,
    pdf_url TEXT,
    remarks TEXT,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    status TEXT DEFAULT 'completed'
);

-- ── 4. PERFORMANCE INDEXES ───────────────────────────────────────
-- Notifications
CREATE INDEX IF NOT EXISTS idx_notif_user_id ON public.notifications("userId");
CREATE INDEX IF NOT EXISTS idx_notif_announcement_id ON public.notifications(announcement_id);
CREATE INDEX IF NOT EXISTS idx_notif_is_read ON public.notifications("isRead");
CREATE INDEX IF NOT EXISTS idx_notif_created_at ON public.notifications("createdAt" DESC);
CREATE INDEX IF NOT EXISTS idx_notif_user_unread ON public.notifications("userId", "isRead") WHERE "isRead" = FALSE;

-- Announcements
CREATE INDEX IF NOT EXISTS idx_ann_created_by ON public.announcements(created_by_id);
CREATE INDEX IF NOT EXISTS idx_ann_target ON public.announcements(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_ann_created_at ON public.announcements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ann_reads_lookup ON public.announcement_reads(announcement_id, user_id);
CREATE INDEX IF NOT EXISTS idx_ann_reads_user ON public.announcement_reads(user_id);

-- Completed Works
CREATE INDEX IF NOT EXISTS idx_completed_works_ward_member ON public.completed_works(ward_member_id);
CREATE INDEX IF NOT EXISTS idx_completed_works_citizen ON public.completed_works(citizen_id);
CREATE INDEX IF NOT EXISTS idx_completed_works_complaint ON public.completed_works(complaint_id);
CREATE INDEX IF NOT EXISTS idx_completed_works_created_at ON public.completed_works(created_at DESC);

-- ── 5. BROADCAST STATISTICS VIEW ─────────────────────────────────
CREATE OR REPLACE VIEW public.v_broadcast_stats AS
SELECT
  a.id                                                        AS announcement_id,
  a.title,
  a.message,
  a.created_by_id                                             AS sender_id,
  COALESCE(a.sender_name, a.created_by_name)                  AS sender_name,
  COALESCE(a.sender_role, a.created_by_role)                  AS sender_role,
  a.target_audience,
  a.target_type,
  a.target_id,
  a.image_url,
  a.voice_url,
  a.pdf_url,
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
  a.created_by_id, a.sender_name, a.created_by_name,
  a.sender_role, a.created_by_role,
  a.target_audience, a.target_type, a.target_id,
  a.image_url, a.voice_url, a.pdf_url, a.attachment_url,
  a.created_at, a.updated_at;

-- ── 6. FUNCTIONS AND TRIGGERS ────────────────────────────────────

-- Auto-create notifications for announcements
CREATE OR REPLACE FUNCTION public.auto_create_announcement_notifications()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_target_roles TEXT[];
  v_inserted_count INT;
BEGIN
  IF NEW.target_type = 'all' THEN
    v_target_roles := ARRAY['citizen','wardAdmin','categoryOfficer','mandalOfficer'];
  ELSIF NEW.target_type = 'role' AND NEW.target_id IS NOT NULL THEN
    v_target_roles := ARRAY[NEW.target_id];
  ELSE
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

  INSERT INTO public.notifications (
    id, "userId", title, body, "createdAt", "isRead", type, notification_type, announcement_id, receiver_role
  )
  SELECT
    'annnotif_' || NEW.id || '_' || u.id, u.id, NEW.title, LEFT(NEW.message, 200), NOW(), FALSE, 'announcement', 'announcement', NEW.id, u.role
  FROM public.users u
  WHERE u.role = ANY(v_target_roles) AND u.id <> NEW.created_by_id;

  GET DIAGNOSTICS v_inserted_count = ROW_COUNT;

  UPDATE public.announcements
     SET total_sent = v_inserted_count, updated_at = NOW()
   WHERE id = NEW.id;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_auto_announcement_notifications ON public.announcements;
CREATE TRIGGER trg_auto_announcement_notifications
  AFTER INSERT ON public.announcements
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_create_announcement_notifications();

-- Sync announcement reads on read
CREATE OR REPLACE FUNCTION public.sync_announcement_reads_on_read()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW."isRead" = TRUE AND OLD."isRead" = FALSE AND NEW.announcement_id IS NOT NULL THEN
    INSERT INTO public.announcement_reads (id, announcement_id, user_id, read_at)
    VALUES ('read_' || NEW.announcement_id || '_' || NEW."userId", NEW.announcement_id, NEW."userId", COALESCE(NEW.read_at, NOW()))
    ON CONFLICT (id) DO UPDATE SET read_at = COALESCE(EXCLUDED.read_at, NOW());

    NEW.read_at := COALESCE(NEW.read_at, NOW());
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_announcement_reads ON public.notifications;
CREATE TRIGGER trg_sync_announcement_reads
  BEFORE UPDATE OF "isRead" ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_announcement_reads_on_read();

-- Auto-create notifications for completed works
CREATE OR REPLACE FUNCTION public.auto_notify_completed_work()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.notifications (
        id,
        "userId",
        title,
        body,
        "complaintId",
        type,
        notification_type,
        reference_id,
        "isRead",
        "createdAt"
    ) VALUES (
        'notif_' || gen_random_uuid()::text,
        NEW.citizen_id,
        'Work Completed: ' || COALESCE((SELECT category FROM public.complaints WHERE id = NEW.complaint_id), NEW.title),
        'Your complaint work has been completed successfully. Please review the completed work.',
        NEW.complaint_id,
        'completed_work',
        'completed_work',
        NEW.id,
        FALSE,
        NOW()
    );

    UPDATE public.complaints 
    SET status = 'resolved', 
        "resolvedAt" = NOW(),
        "resolvedImageUrl" = NEW.after_image_url
    WHERE id = NEW.complaint_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_notify_completed_work ON public.completed_works;
CREATE TRIGGER trg_notify_completed_work
AFTER INSERT ON public.completed_works
FOR EACH ROW
EXECUTE FUNCTION public.auto_notify_completed_work();

-- ── 7. ROW LEVEL SECURITY (RLS) ──────────────────────────────────
-- Announcements & Notifications
DROP POLICY IF EXISTS "Enable read/write for anonymous users on announcements" ON public.announcements;
DROP POLICY IF EXISTS "announcements_open_access" ON public.announcements;
CREATE POLICY "announcements_open_access" ON public.announcements FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Enable read/write for anonymous users on notifications" ON public.notifications;
DROP POLICY IF EXISTS "notifications_open_access" ON public.notifications;
CREATE POLICY "notifications_open_access" ON public.notifications FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Enable read/write for anonymous users on announcement_reads" ON public.announcement_reads;
DROP POLICY IF EXISTS "announcement_reads_open_access" ON public.announcement_reads;
CREATE POLICY "announcement_reads_open_access" ON public.announcement_reads FOR ALL USING (true) WITH CHECK (true);

-- Completed Works
ALTER TABLE public.completed_works ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Citizens can view their own completed works" ON public.completed_works;
CREATE POLICY "Citizens can view their own completed works" ON public.completed_works FOR SELECT USING (citizen_id = auth.uid());

DROP POLICY IF EXISTS "Ward Members can view their uploaded works" ON public.completed_works;
CREATE POLICY "Ward Members can view their uploaded works" ON public.completed_works FOR SELECT USING (ward_member_id = auth.uid());

DROP POLICY IF EXISTS "Ward Members can insert works" ON public.completed_works;
CREATE POLICY "Ward Members can insert works" ON public.completed_works FOR INSERT WITH CHECK (ward_member_id = auth.uid());

DROP POLICY IF EXISTS "Ward Members can update their works" ON public.completed_works;
CREATE POLICY "Ward Members can update their works" ON public.completed_works FOR UPDATE USING (ward_member_id = auth.uid());

DROP POLICY IF EXISTS "Super Admins can view all completed works" ON public.completed_works;
CREATE POLICY "Super Admins can view all completed works" ON public.completed_works FOR SELECT USING (EXISTS (SELECT 1 FROM public.users WHERE users.id = auth.uid() AND users.role = 'superAdmin'));

DROP POLICY IF EXISTS "Mandal Officers can view mandal works" ON public.completed_works;
CREATE POLICY "Mandal Officers can view mandal works" ON public.completed_works FOR SELECT USING (EXISTS (SELECT 1 FROM public.users u JOIN public.complaints c ON c.id = completed_works.complaint_id WHERE u.id = auth.uid() AND u.role = 'mandalOfficer' AND c.mandal_name = u.mandal_name));

DROP POLICY IF EXISTS "Category Officers can view assigned works" ON public.completed_works;
CREATE POLICY "Category Officers can view assigned works" ON public.completed_works FOR SELECT USING (EXISTS (SELECT 1 FROM public.users u JOIN public.complaints c ON c.id = completed_works.complaint_id WHERE u.id = auth.uid() AND u.role = 'categoryOfficer' AND (c.assigned_officer_id = u.id OR c.category = u.department)));

-- ── 8. ENABLE REALTIME ───────────────────────────────────────────
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
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.completed_works;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
END;
$$;

-- ── 9. STORAGE BUCKET & POLICIES ─────────────────────────────────
INSERT INTO storage.buckets (id, name, public)
VALUES ('government-files', 'government-files', true)
ON CONFLICT (id) DO NOTHING;

-- Single comprehensive policy set for the bucket
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
