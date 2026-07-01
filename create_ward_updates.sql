-- 1. Create the ward_updates table
CREATE TABLE IF NOT EXISTS public.ward_updates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ward_id TEXT NOT NULL,
    ward_name TEXT NOT NULL,
    ward_member_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    image_urls TEXT[] NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Enable Row Level Security (RLS)
ALTER TABLE public.ward_updates ENABLE ROW LEVEL SECURITY;

-- 3. Create policies
-- Allow anyone to read ward updates
CREATE POLICY "Enable read access for all users" ON public.ward_updates
    FOR SELECT USING (true);

-- Allow authenticated users (specifically ward members) to insert their own updates
CREATE POLICY "Enable insert for authenticated users" ON public.ward_updates
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Allow users to update their own updates
CREATE POLICY "Enable update for owners" ON public.ward_updates
    FOR UPDATE USING (auth.uid()::text = ward_member_id);

-- Allow users to delete their own updates
CREATE POLICY "Enable delete for owners" ON public.ward_updates
    FOR DELETE USING (auth.uid()::text = ward_member_id);

-- 4. Enable Realtime
-- Important: You must also go to Database -> Replication in Supabase Dashboard 
-- and enable replication for the `ward_updates` table.
ALTER PUBLICATION supabase_realtime ADD TABLE public.ward_updates;

-- 5. Create Storage Bucket for Work Update Images (if it doesn't exist)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('work_updates', 'work_updates', true)
ON CONFLICT (id) DO NOTHING;

-- 6. Storage Policies
CREATE POLICY "Public Access for work_updates"
ON storage.objects FOR SELECT
USING (bucket_id = 'work_updates');

CREATE POLICY "Enable insert for work_updates"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'work_updates' AND auth.role() = 'authenticated');
