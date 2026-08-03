-- =====================================================================
-- CreatorInc — Database triggers
-- =====================================================================
-- These triggers connect the helper functions above to auth and profile
-- lifecycle events.

-- ---------- 1. AUTH USER CREATION ----------
-- When a new auth user is inserted, create the matching profile record.
create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute procedure public.handle_new_user();

-- ---------- 2. UPDATED_AT TRACKING ----------
-- Keep creator and brand profile timestamps current on each update.
create trigger set_creator_profiles_updated_at
  before update on public.creator_profiles
  for each row
  execute function public.set_updated_at();

create trigger set_brand_profiles_updated_at
  before update on public.brand_profiles
  for each row
  execute function public.set_updated_at();