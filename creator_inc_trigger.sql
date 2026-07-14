-- Runs only after a new authentication user is created.
-- Calls handle_new_user().
-- creates the corresponding row in public.profiles.

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- trigger functions to update time stamp on updates on creator and brand profiles

create trigger set_creator_profiles_updated_at before update on public.creator_profiles for each row execute function public.set_updated_at();
create trigger set_brand_profiles_updated_at before update on public.brand_profiles for each row execute function public.set_updated_at();