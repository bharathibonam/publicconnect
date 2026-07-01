-- ==============================================================================
-- COMPLETED WORKS & NOTIFICATION SYSTEM
-- ==============================================================================

-- 1. Create completed_works table
CREATE TABLE IF NOT EXISTS public.completed_works (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    complaint_id UUID REFERENCES public.complaints(id) ON DELETE CASCADE,
    ward_member_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    citizen_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
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

-- 2. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_completed_works_ward_member ON public.completed_works(ward_member_id);
CREATE INDEX IF NOT EXISTS idx_completed_works_citizen ON public.completed_works(citizen_id);
CREATE INDEX IF NOT EXISTS idx_completed_works_complaint ON public.completed_works(complaint_id);
CREATE INDEX IF NOT EXISTS idx_completed_works_created_at ON public.completed_works(created_at DESC);

-- 3. Enable RLS
ALTER TABLE public.completed_works ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies
-- Citizen: Can read only their own works
CREATE POLICY "Citizens can view their own completed works"
ON public.completed_works FOR SELECT
USING (citizen_id = auth.uid());

-- Ward Member: Can read/insert/update their own uploaded works
CREATE POLICY "Ward Members can view their uploaded works"
ON public.completed_works FOR SELECT
USING (ward_member_id = auth.uid());

CREATE POLICY "Ward Members can insert works"
ON public.completed_works FOR INSERT
WITH CHECK (ward_member_id = auth.uid());

CREATE POLICY "Ward Members can update their works"
ON public.completed_works FOR UPDATE
USING (ward_member_id = auth.uid());

-- MLA (superAdmin): Can view all
CREATE POLICY "Super Admins can view all completed works"
ON public.completed_works FOR SELECT
USING (EXISTS (
  SELECT 1 FROM public.users 
  WHERE users.id = auth.uid() AND users.role = 'superAdmin'
));

-- Mandal Officer / Category Officer:
-- Based on the user's view scope, similar to complaints
CREATE POLICY "Mandal Officers can view mandal works"
ON public.completed_works FOR SELECT
USING (EXISTS (
  SELECT 1 FROM public.users u 
  JOIN public.complaints c ON c.id = completed_works.complaint_id
  WHERE u.id = auth.uid() AND u.role = 'mandalOfficer' AND c.mandal_name = u.mandal_name
));

CREATE POLICY "Category Officers can view assigned works"
ON public.completed_works FOR SELECT
USING (EXISTS (
  SELECT 1 FROM public.users u 
  JOIN public.complaints c ON c.id = completed_works.complaint_id
  WHERE u.id = auth.uid() AND u.role = 'categoryOfficer' AND (c.assigned_officer_id = u.id OR c.category = u.department)
));

-- 5. Realtime setup
ALTER PUBLICATION supabase_realtime ADD TABLE public.completed_works;

-- 6. Trigger for Automatic Notification
CREATE OR REPLACE FUNCTION public.auto_notify_completed_work()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.notifications (
        user_id,
        title,
        message,
        type,
        reference_id,
        is_read,
        created_at
    ) VALUES (
        NEW.citizen_id,
        'Work Completed: ' || NEW.title,
        'Your complaint work has been completed.',
        'completed_work',
        NEW.id,
        FALSE,
        NOW()
    );

    -- Update the related complaint status to 'resolved' and update its timestamp
    UPDATE public.complaints 
    SET status = 'resolved', 
        resolved_at = NOW() 
    WHERE id = NEW.complaint_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_completed_work ON public.completed_works;
CREATE TRIGGER trg_notify_completed_work
AFTER INSERT ON public.completed_works
FOR EACH ROW
EXECUTE FUNCTION public.auto_notify_completed_work();

-- 7. Storage Policies
-- Assuming 'government-files' bucket already exists from broadcast system
-- Allow authenticated users to upload to completed-works/
CREATE POLICY "Users can upload completed works files"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'government-files' AND 
    (storage.foldername(name))[1] = 'completed-works'
);

-- Allow everyone to read completed works files
CREATE POLICY "Anyone can read completed works files"
ON storage.objects FOR SELECT
TO public
USING (
    bucket_id = 'government-files' AND 
    (storage.foldername(name))[1] = 'completed-works'
);
