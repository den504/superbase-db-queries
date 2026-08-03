-- =====================================================================
-- CreatorInc — Storage access policies
-- =====================================================================
-- These rules control which authenticated users can read, write, and update
-- files in Supabase Storage buckets.

-- ---------- 1. PROFILE PHOTO BUCKET ----------
-- Users may manage only files stored inside a folder named after their own
-- auth user ID.
create policy "profile_photos_insert_own"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'profile-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "profile_photos_update_own"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'profile-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'profile-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "profile_photos_select_own"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'profile-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- ---------- 2. CREATOR VIDEO BUCKET ----------
-- Creators can manage only their own shorts and video assets.
create policy "Creators can upload own shorts"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'creator-videos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Creators can update own shorts"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'creator-videos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Creators can view own shorts"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'creator-videos'
  and (storage.foldername(name))[1] = auth.uid()::text
);