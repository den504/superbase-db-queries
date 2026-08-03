-- =====================================================================
-- CreatorInc — Helper functions
-- =====================================================================
-- These functions support auth lifecycle automation and automatic
-- timestamp updates for profile-related tables.

-- ---------- 1. AUTH USER CREATION HELPERS ----------
-- Creates a matching row in public.profiles whenever a new Supabase auth
-- user is created.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.profiles (id, email, role)
  values (
    new.id,
    new.email,
    (new.raw_user_meta_data->>'role')::public.user_role
  );

  return new;
end;
$$;

-- ---------- 2. UPDATED_AT HELPERS ----------
-- Updates the updated_at column on profile-like tables whenever a row is
-- modified.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;