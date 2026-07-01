-- ==========================================
-- FRESH START: DROP OLD TABLES & POLICIES
-- ==========================================
-- This guarantees a completely clean slate.
-- WARNING: This will delete any existing data in these tables.
DROP TABLE IF EXISTS public.announcement_reads CASCADE;
DROP TABLE IF EXISTS public.announcements CASCADE;
DROP TABLE IF EXISTS public.complaint_chats CASCADE;
DROP TABLE IF EXISTS public.chat_messages CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.ward_updates CASCADE;
DROP TABLE IF EXISTS public.complaints CASCADE;
DROP TABLE IF EXISTS public.broadcast_alerts CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;
DROP TABLE IF EXISTS public.wards CASCADE;
DROP TABLE IF EXISTS public.app_config CASCADE;

-- ==========================================
-- 1. CREATE FRESH TABLES
-- ==========================================

CREATE TABLE public.wards (
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

CREATE TABLE public.app_config (
    id TEXT PRIMARY KEY,
    "politicianName" TEXT NOT NULL,
    "politicianRole" TEXT NOT NULL,
    "constituencyName" TEXT NOT NULL,
    "partyLogoUrl" TEXT,
    "politicianImageUrl" TEXT,
    "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

CREATE TABLE public.users (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    "phoneNumber" TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL, 
    role TEXT NOT NULL CHECK (role IN ('citizen', 'wardAdmin', 'superAdmin', 'categoryOfficer', 'mandalOfficer')),
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

CREATE TABLE public.complaints (
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
    status TEXT NOT NULL CHECK (status IN ('submitted', 'inProgress', 'resolved')),
    priority TEXT NOT NULL CHECK (priority IN ('low', 'medium', 'high')),
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
    "resolvedAt" TIMESTAMP WITH TIME ZONE,
    "feedbackRating" TEXT,
    "isClosed" BOOLEAN DEFAULT FALSE
);

CREATE TABLE public.broadcast_alerts (
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

CREATE TABLE public.chat_messages (
    id TEXT PRIMARY KEY,
    "complaintId" TEXT NOT NULL REFERENCES public.complaints(id) ON DELETE CASCADE,
    "senderId" TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    "receiverId" TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    is_read BOOLEAN DEFAULT FALSE
);

CREATE TABLE public.complaint_chats (
    id TEXT PRIMARY KEY,
    complaint_id TEXT NOT NULL REFERENCES public.complaints(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

CREATE TABLE public.announcements (
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

CREATE TABLE public.announcement_reads (
    id TEXT PRIMARY KEY,
    announcement_id TEXT NOT NULL REFERENCES public.announcements(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    read_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

CREATE TABLE public.notifications (
    id TEXT PRIMARY KEY,
    "userId" TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    "isRead" BOOLEAN DEFAULT FALSE,
    "complaintId" TEXT,
    type TEXT
);

CREATE TABLE public.ward_updates (
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

-- ==========================================
-- 2. ROW LEVEL SECURITY (RLS)
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

-- Allow read/write access to all tables for the app to function properly
CREATE POLICY "Enable read/write for anonymous users on wards" ON public.wards FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable read/write for anonymous users on users" ON public.users FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable read/write for anonymous users on complaints" ON public.complaints FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable read/write for anonymous users on broadcast_alerts" ON public.broadcast_alerts FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable read/write for anonymous users on chat_messages" ON public.chat_messages FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable read/write for anonymous users on app_config" ON public.app_config FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable read/write for anonymous users on complaint_chats" ON public.complaint_chats FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable read/write for anonymous users on announcements" ON public.announcements FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable read/write for anonymous users on announcement_reads" ON public.announcement_reads FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable read/write for anonymous users on notifications" ON public.notifications FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable read/write for anonymous users on ward_updates" ON public.ward_updates FOR ALL USING (true) WITH CHECK (true);

-- Enable Realtime for crucial tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.wards;
ALTER PUBLICATION supabase_realtime ADD TABLE public.users;
ALTER PUBLICATION supabase_realtime ADD TABLE public.complaints;
ALTER PUBLICATION supabase_realtime ADD TABLE public.broadcast_alerts;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.announcements;
ALTER PUBLICATION supabase_realtime ADD TABLE public.ward_updates;

-- ==========================================
-- 3. STORAGE BUCKETS SETUP
-- ==========================================
INSERT INTO storage.buckets (id, name, public) VALUES ('complaints', 'complaints', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('profiles', 'profiles', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('broadcast_audio', 'broadcast_audio', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('app_assets', 'app_assets', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('work_updates', 'work_updates', true) ON CONFLICT DO NOTHING;

-- Drop existing storage policies just in case
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Public Insert" ON storage.objects;
DROP POLICY IF EXISTS "Public Update" ON storage.objects;
DROP POLICY IF EXISTS "Public Delete" ON storage.objects;

-- Enable public access policies for storage
CREATE POLICY "Public Access" ON storage.objects FOR SELECT USING (bucket_id IN ('complaints', 'profiles', 'broadcast_audio', 'app_assets', 'work_updates'));
CREATE POLICY "Public Insert" ON storage.objects FOR INSERT WITH CHECK (bucket_id IN ('complaints', 'profiles', 'broadcast_audio', 'app_assets', 'work_updates'));
CREATE POLICY "Public Update" ON storage.objects FOR UPDATE USING (bucket_id IN ('complaints', 'profiles', 'broadcast_audio', 'app_assets', 'work_updates'));
CREATE POLICY "Public Delete" ON storage.objects FOR DELETE USING (bucket_id IN ('complaints', 'profiles', 'broadcast_audio', 'app_assets', 'work_updates'));
