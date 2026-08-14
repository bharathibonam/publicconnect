-- ==============================================================================
-- SMART GOVERNANCE: FINAL PRODUCTION SYNCHRONIZATION MIGRATION
-- ==============================================================================
-- This script is completely idempotent. It will safely create any missing tables
-- and add any missing columns without deleting your existing data.

-- ==========================================
-- 1. BASE TABLES CREATION (IF NOT EXIST)
-- ==========================================

CREATE TABLE IF NOT EXISTS public.wards (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    "adminId" TEXT,
    "adminName" TEXT,
    "centerLatitude" DOUBLE PRECISION NOT NULL,
    "centerLongitude" DOUBLE PRECISION NOT NULL,
    "minLat" DOUBLE PRECISION NOT NULL,
    "maxLat" DOUBLE PRECISION NOT NULL,
    "minLng" DOUBLE PRECISION NOT NULL,
    "maxLng" DOUBLE PRECISION NOT NULL
);

CREATE TABLE IF NOT EXISTS public.app_config (
    id TEXT PRIMARY KEY,
    "politicianName" TEXT NOT NULL,
    "politicianRole" TEXT NOT NULL,
    "constituencyName" TEXT NOT NULL,
    "partyLogoUrl" TEXT,
    "politicianImageUrl" TEXT,
    "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.users (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    "phoneNumber" TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL, 
    role TEXT NOT NULL,
    "wardId" TEXT,
    "wardName" TEXT,
    "mandalName" TEXT,
    "villageName" TEXT,
    "officerRole" TEXT,
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    "profilePhotoUrl" TEXT,
    "isEmployed" BOOLEAN,
    education TEXT
);

CREATE TABLE IF NOT EXISTS public.complaints (
    id TEXT PRIMARY KEY,
    "userId" TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    "citizenName" TEXT NOT NULL,
    "citizenPhone" TEXT NOT NULL,
    category TEXT NOT NULL,
    description TEXT NOT NULL,
    "imageUrl" TEXT,
    "resolvedImageUrl" TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    "wardId" TEXT NOT NULL REFERENCES public.wards(id) ON DELETE CASCADE,
    "wardName" TEXT,
    "villageName" TEXT,
    "mandalName" TEXT,
    address TEXT,
    "assignedOfficerId" TEXT REFERENCES public.users(id) ON DELETE SET NULL,
    "deviceInfo" TEXT,
    status TEXT NOT NULL,
    priority TEXT NOT NULL,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
    "resolvedAt" TIMESTAMP WITH TIME ZONE,
    "feedbackRating" TEXT,
    "isClosed" BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS public.broadcast_alerts (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    "wardId" TEXT NOT NULL,
    "wardName" TEXT,
    "createdBy" TEXT NOT NULL,
    "createdByRole" TEXT NOT NULL,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
    "targetAudience" TEXT NOT NULL,
    "audioUrl" TEXT
);

CREATE TABLE IF NOT EXISTS public.chat_messages (
    id TEXT PRIMARY KEY,
    "complaintId" TEXT NOT NULL REFERENCES public.complaints(id) ON DELETE CASCADE,
    "senderId" TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    "receiverId" TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    is_read BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS public.complaint_chats (
    id TEXT PRIMARY KEY,
    complaint_id TEXT NOT NULL REFERENCES public.complaints(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.announcements (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    attachment_url TEXT,
    created_by_id TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_by_role TEXT NOT NULL,
    created_by_name TEXT NOT NULL,
    category_scope TEXT,
    target_audience TEXT NOT NULL,
    target_mandal TEXT,
    target_panchayat TEXT,
    target_ward TEXT,
    total_sent INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.announcement_reads (
    id TEXT PRIMARY KEY,
    announcement_id TEXT NOT NULL REFERENCES public.announcements(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    read_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.notifications (
    id TEXT PRIMARY KEY,
    "userId" TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    "isRead" BOOLEAN DEFAULT FALSE,
    "complaintId" TEXT,
    type TEXT
);

CREATE TABLE IF NOT EXISTS public.ward_updates (
    id TEXT PRIMARY KEY,
    ward_id TEXT NOT NULL,
    ward_name TEXT NOT NULL,
    ward_member_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    image_urls TEXT[] NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

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
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    status TEXT DEFAULT 'completed'
);


-- ==========================================
-- 2. ALTER TABLES: ADD ALL MISSING COLUMNS
-- ==========================================

-- USERS
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS "profileImageUrl" TEXT,
  ADD COLUMN IF NOT EXISTS "fcmToken" TEXT;

-- COMPLAINTS
ALTER TABLE public.complaints
  ADD COLUMN IF NOT EXISTS "voiceUrl" TEXT,
  ADD COLUMN IF NOT EXISTS "isPushed" BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS "pushedTo" TEXT;

-- WARD UPDATES
ALTER TABLE public.ward_updates
  ADD COLUMN IF NOT EXISTS location TEXT,
  ADD COLUMN IF NOT EXISTS author_name TEXT;

-- ANNOUNCEMENTS
ALTER TABLE public.announcements
  ADD COLUMN IF NOT EXISTS image_url TEXT,
  ADD COLUMN IF NOT EXISTS voice_url TEXT,
  ADD COLUMN IF NOT EXISTS pdf_url TEXT,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS sender_role TEXT,
  ADD COLUMN IF NOT EXISTS sender_name TEXT,
  ADD COLUMN IF NOT EXISTS target_type TEXT DEFAULT 'role',
  ADD COLUMN IF NOT EXISTS target_id TEXT;

UPDATE public.announcements SET sender_role = created_by_role WHERE sender_role IS NULL;
UPDATE public.announcements SET sender_name = created_by_name WHERE sender_name IS NULL;

-- NOTIFICATIONS
ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS announcement_id TEXT REFERENCES public.announcements(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS receiver_role TEXT,
  ADD COLUMN IF NOT EXISTS read_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS notification_type TEXT,
  ADD COLUMN IF NOT EXISTS reference_id TEXT;

UPDATE public.notifications SET notification_type = type WHERE notification_type IS NULL AND type IS NOT NULL;


-- ==========================================
-- 3. ENABLE ROW LEVEL SECURITY (RLS)
-- ==========================================

ALTER TABLE public.wards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.broadcast_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaint_chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcement_reads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ward_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.completed_works ENABLE ROW LEVEL SECURITY;

-- Apply Open Access (Flutter app handles specific scopes via its logic)
DO $$ 
DECLARE
    t TEXT;
BEGIN
    FOR t IN 
        SELECT unnest(ARRAY[
            'wards', 'users', 'complaints', 'broadcast_alerts', 'chat_messages', 
            'app_config', 'complaint_chats', 'announcements', 'announcement_reads', 
            'notifications', 'ward_updates', 'completed_works'
        ])
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS "Enable read/write for anonymous users on %I" ON public.%I', t, t);
        EXECUTE format('DROP POLICY IF EXISTS "%I_open_access" ON public.%I', t, t);
        EXECUTE format('CREATE POLICY "%I_open_access" ON public.%I FOR ALL USING (true) WITH CHECK (true)', t, t);
    END LOOP;
END $$;


-- ==========================================
-- 4. REALTIME SETUP
-- ==========================================

DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.wards;
  ALTER PUBLICATION supabase_realtime ADD TABLE public.users;
  ALTER PUBLICATION supabase_realtime ADD TABLE public.complaints;
  ALTER PUBLICATION supabase_realtime ADD TABLE public.broadcast_alerts;
  ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
  ALTER PUBLICATION supabase_realtime ADD TABLE public.announcements;
  ALTER PUBLICATION supabase_realtime ADD TABLE public.ward_updates;
  ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  ALTER PUBLICATION supabase_realtime ADD TABLE public.announcement_reads;
  ALTER PUBLICATION supabase_realtime ADD TABLE public.completed_works;
EXCEPTION WHEN duplicate_object THEN NULL;
END;
$$;


-- ==========================================
-- 5. STORAGE BUCKETS & POLICIES
-- ==========================================

INSERT INTO storage.buckets (id, name, public) VALUES ('complaints', 'complaints', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('profiles', 'profiles', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('broadcast_audio', 'broadcast_audio', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('app_assets', 'app_assets', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('work_updates', 'work_updates', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('government-files', 'government-files', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('completed-works', 'completed-works', true) ON CONFLICT DO NOTHING;

DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Public Insert" ON storage.objects;
DROP POLICY IF EXISTS "Public Update" ON storage.objects;
DROP POLICY IF EXISTS "Public Delete" ON storage.objects;

CREATE POLICY "Public Access" ON storage.objects FOR SELECT USING (bucket_id IN ('complaints', 'profiles', 'broadcast_audio', 'app_assets', 'work_updates', 'government-files', 'completed-works'));
CREATE POLICY "Public Insert" ON storage.objects FOR INSERT WITH CHECK (bucket_id IN ('complaints', 'profiles', 'broadcast_audio', 'app_assets', 'work_updates', 'government-files', 'completed-works'));
CREATE POLICY "Public Update" ON storage.objects FOR UPDATE USING (bucket_id IN ('complaints', 'profiles', 'broadcast_audio', 'app_assets', 'work_updates', 'government-files', 'completed-works'));
CREATE POLICY "Public Delete" ON storage.objects FOR DELETE USING (bucket_id IN ('complaints', 'profiles', 'broadcast_audio', 'app_assets', 'work_updates', 'government-files', 'completed-works'));


-- ==========================================
-- 6. VIEWS & TRIGGERS (Auto-Notifications)
-- ==========================================

CREATE OR REPLACE VIEW public.v_broadcast_stats AS
SELECT
  a.id AS announcement_id,
  a.title, a.message, a.created_by_id AS sender_id, COALESCE(a.sender_name, a.created_by_name) AS sender_name,
  COALESCE(a.sender_role, a.created_by_role) AS sender_role,
  a.target_audience, a.target_type, a.target_id, a.image_url, a.voice_url, a.pdf_url, a.attachment_url,
  a.created_at, a.updated_at,
  COUNT(n.id) AS total_delivered,
  COUNT(n.id) FILTER (WHERE n."isRead" = TRUE) AS read_count,
  COUNT(n.id) FILTER (WHERE n."isRead" = FALSE) AS unread_count,
  CASE WHEN COUNT(n.id) = 0 THEN 0.0 ELSE ROUND(COUNT(n.id) FILTER (WHERE n."isRead" = TRUE) * 100.0 / COUNT(n.id), 1) END AS read_percentage
FROM public.announcements a
LEFT JOIN public.notifications n ON n.announcement_id = a.id AND n.notification_type = 'announcement'
GROUP BY a.id, a.title, a.message, a.created_by_id, a.sender_name, a.created_by_name, a.sender_role, a.created_by_role, a.target_audience, a.target_type, a.target_id, a.image_url, a.voice_url, a.pdf_url, a.attachment_url, a.created_at, a.updated_at;

-- Trigger: auto_create_announcement_notifications
CREATE OR REPLACE FUNCTION public.auto_create_announcement_notifications() RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_target_roles TEXT[]; v_inserted_count INT;
BEGIN
  IF NEW.target_type = 'all' THEN v_target_roles := ARRAY['citizen','wardAdmin','categoryOfficer','mandalOfficer'];
  ELSIF NEW.target_type = 'role' AND NEW.target_id IS NOT NULL THEN v_target_roles := ARRAY[NEW.target_id];
  ELSE v_target_roles := ARRAY['citizen','wardAdmin','categoryOfficer','mandalOfficer']; END IF;

  INSERT INTO public.notifications (id, "userId", title, body, "createdAt", "isRead", type, notification_type, announcement_id, receiver_role)
  SELECT 'annnotif_' || NEW.id || '_' || u.id, u.id, NEW.title, LEFT(NEW.message, 200), NOW(), FALSE, 'announcement', 'announcement', NEW.id, u.role
  FROM public.users u WHERE u.role = ANY(v_target_roles) AND u.id <> NEW.created_by_id;

  GET DIAGNOSTICS v_inserted_count = ROW_COUNT;
  UPDATE public.announcements SET total_sent = v_inserted_count, updated_at = NOW() WHERE id = NEW.id;
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS trg_auto_announcement_notifications ON public.announcements;
CREATE TRIGGER trg_auto_announcement_notifications AFTER INSERT ON public.announcements FOR EACH ROW EXECUTE FUNCTION public.auto_create_announcement_notifications();

-- Trigger: auto_notify_completed_work
CREATE OR REPLACE FUNCTION public.auto_notify_completed_work() RETURNS TRIGGER AS $$
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
END; $$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_notify_completed_work ON public.completed_works;
CREATE TRIGGER trg_notify_completed_work AFTER INSERT ON public.completed_works FOR EACH ROW EXECUTE FUNCTION public.auto_notify_completed_work();
