
-- //It allows a logged-in user to upload a photo only inside a folder named with their own user ID.
create policy "profile_photos_insert_own"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'profile-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

--allow users to replace their own photo during Edit.


create policy "profile_photos_update_own"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'profile-photos' and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'profile-photos' and (storage.foldername(name))[1] = auth.uid()::text
);

--allow the app to check the user’s existing photo before replacing it.

create policy "profile_photos_select_own"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'profile-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);


---- storage policy for video storage bucket----------

create policy "Creators can upload own shorts"
on storage.objects for insert
to authenticated
with check (
    bucket_id = 'creator-videos'
    and (storage.foldername(name))[1] = auth.uid()::text
);



create policy "Creators can update own shorts"
on storage.objects for update
to authenticated
using (
    bucket_id = 'creator-videos'
    and (storage.foldername(name))[1] = auth.uid()::text
);


create policy "Creators can view own shorts"
on storage.objects for select
to authenticated
using (
    bucket_id = 'creator-videos'
    and (storage.foldername(name))[1] = auth.uid()::text
);