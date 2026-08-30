-- =====================================================================
-- CreatorInc — Row Level Security (RLS) policies
-- =====================================================================
-- RLS controls which rows authenticated users can read or change.
-- auth.uid()  = the current user id, or null for anonymous requests.
-- auth.role() = 'authenticated' for signed-in users, 'anon' otherwise.
-- Pattern: every policy follows "for <action> using/with check (<condition>)".

-- ---------- 0. ENABLE RLS ON TABLES ----------
-- By default, these tables deny access until an explicit policy allows it.
alter table profiles                enable row level security;
alter table creator_profiles        enable row level security;
alter table brand_profiles          enable row level security;
alter table public.gigs            enable row level security;
alter table creator_shorts        enable row level security;

-- ---------- 1. PROFILE ACCESS ----------
-- Users can only read or update their own base profile row.
create policy profiles_select_own on profiles
  for select using (id = auth.uid());

create policy profiles_update_own on profiles
  for update using (id = auth.uid());

-- ---------- 2. CREATOR PROFILE ACCESS ----------
-- Authenticated users may discover creator profiles, but creators can only
-- modify their own profile record.
create policy creator_read_all on creator_profiles
  for select using (auth.role() = 'authenticated');

create policy creator_modify_own on creator_profiles
  for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ---------- 3. BRAND PROFILE ACCESS ----------
-- Authenticated users may discover brand profiles, but brands can only
-- modify their own record.
create policy brand_read_all on brand_profiles
  for select using (auth.role() = 'authenticated');

create policy brand_modify_own on brand_profiles
  for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());


-- ---------- 12. CREATOR SHORT ACCESS ----------
-- Creators manage only their own shorts.
create policy "Creators manage own shorts"
  on creator_shorts
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------- 13. CLEANUP AND GRANTS ----------
-- Remove older duplicate policies if they exist.
drop policy if exists "Users can read own profile" on public.profiles;
drop policy if exists "Users can read their own profile" on public.profiles;

-- Grant access for profile-related tables to authenticated users.
grant select, insert, update on public.creator_profiles to authenticated;
grant select, insert, update on public.brand_profiles to authenticated;

-- Grant full access to gigs for authenticated users.
grant select, insert, update, delete on table public.gigs to authenticated;

grant select, insert, update, delete on creator_shorts to authenticated;

----authenticated users can discover gigs -------
create policy "Authenticated users can discover open gigs"
on public.gigs
for select
to authenticated
using (status = 'open');

----authenicated users can discover brands ---------
create policy "Authenticated users can discover brands"
on public.brand_profiles
for select
to authenticated
using (true);

-- secure gig_interest with rls 
alter table public.gig_interests enable row level security;



--- confirms authenicated user has a creator profile

create policy "Creators can indicate interest in open gigs"
on public.gig_interests
for insert to authenticated
with check (creator_user_id = auth.uid() and exists (select 1 from public.creator_profiles where user_id = auth.uid()) and exists (select 1 from public.gigs where id = gig_id and status = 'open'));

-- creators can check whether they already indicated interest
create policy "Creators can read their own interests"
on public.gig_interests
for select to authenticated
using (creator_user_id = auth.uid());

-- brands can read interest for their gigs
create policy "Brands can read interests for their gigs"
on public.gig_interests
for select to authenticated
using (exists (select 1 from public.gigs where id = gig_id and brand_id = auth.uid()));

-- [Security → table privileges → creator interest operations]
grant select, insert on table public.gig_interests
to authenticated;


--NOT IN USE
-- alter table portfolio_links         enable row level security;
-- alter table creator_social_accounts enable row level security;
-- alter table creator_social_stats    enable row level security;
-- alter table opportunities           enable row level security;
-- alter table interests               enable row level security;
-- alter table chat_channels           enable row level security;
-- alter table photo_uploads           enable row level security;
-- alter table audit_logs              enable row level security;



-- ---------- 4. OPPORTUNITY ACCESS ----------
-- Open opportunities are visible to everyone, while brands can also manage
-- their own draft, closed, and archived opportunities.
-- create policy opp_read_open on opportunities
--   for select using (
--     status = 'OPEN'
--     or brand_id in (select id from brand_profiles where user_id = auth.uid())
--   );

-- create policy opp_modify_own on opportunities
--   for all using (
--     brand_id in (select id from brand_profiles where user_id = auth.uid())
--   )
--   with check (
--     brand_id in (select id from brand_profiles where user_id = auth.uid())
--   );


-- ---------- 5. INTEREST ACCESS ----------
-- Creators can only manage their own applications, while brands can only
-- view and update applications tied to their own opportunities.
-- create policy interest_creator_insert on interests
--   for insert with check (
--     creator_id in (select id from creator_profiles where user_id = auth.uid())
--   );

-- create policy interest_creator_select on interests
--   for select using (
--     creator_id in (select id from creator_profiles where user_id = auth.uid())
--   );

-- create policy interest_brand_select on interests
--   for select using (
--     opportunity_id in (
--       select o.id
--       from opportunities o
--       join brand_profiles b on b.id = o.brand_id
--       where b.user_id = auth.uid()
--     )
--   );

-- create policy interest_brand_update on interests
--   for update using (
--     opportunity_id in (
--       select o.id
--       from opportunities o
--       join brand_profiles b on b.id = o.brand_id
--       where b.user_id = auth.uid()
--     )
--   );

-- -- ---------- 6. CHAT CHANNEL ACCESS ----------
-- -- A channel is visible only to the creator and brand involved in it.
-- create policy chat_visible_to_parties on chat_channels
--   for select using (
--     creator_id in (select id from creator_profiles where user_id = auth.uid())
--     or brand_id in (select id from brand_profiles where user_id = auth.uid())
--   );

-- -- ---------- 7. PHOTO UPLOAD ACCESS ----------
-- -- Authenticated users may read upload metadata, but only own their own rows.
-- create policy photo_read_all on photo_uploads
--   for select using (auth.role() = 'authenticated');

-- create policy photo_modify_own on photo_uploads
--   for all
--   using (owner_user_id = auth.uid())
--   with check (owner_user_id = auth.uid());

-- -- ---------- 8. SOCIAL ACCOUNT AND SOCIAL STATS ACCESS ----------
-- -- These are publicly discoverable to authenticated users, but only the owner
-- -- may modify them.
-- create policy social_read_all on creator_social_accounts
--   for select using (auth.role() = 'authenticated');

-- create policy social_modify_own on creator_social_accounts
--   for all using (
--     creator_profile_id in (select id from creator_profiles where user_id = auth.uid())
--   )
--   with check (
--     creator_profile_id in (select id from creator_profiles where user_id = auth.uid())
--   );

-- create policy stats_read_all on creator_social_stats
--   for select using (auth.role() = 'authenticated');

-- create policy stats_modify_own on creator_social_stats
--   for all using (
--     social_account_id in (
--       select sa.id
--       from creator_social_accounts sa
--       join creator_profiles cp on cp.id = sa.creator_profile_id
--       where cp.user_id = auth.uid()
--     )
--   );

-- -- ---------- 9. PORTFOLIO LINK ACCESS ----------
-- -- Portfolio links are visible to authenticated users but editable only by the
-- -- owning creator.
-- create policy portfolio_read_all on portfolio_links
--   for select using (auth.role() = 'authenticated');

-- create policy portfolio_modify_own on portfolio_links
--   for all using (
--     creator_profile_id in (select id from creator_profiles where user_id = auth.uid())
--   )
--   with check (
--     creator_profile_id in (select id from creator_profiles where user_id = auth.uid())
--   );

-- -- ---------- 10. AUDIT LOG ACCESS ----------
-- -- Normal users can read only their own audit entries; writes are intended for
-- -- trusted server-side code.
-- create policy audit_select_own on audit_logs
--   for select using (actor_user_id = auth.uid());

-- -- ---------- 11. GIG ACCESS ----------
-- -- Brands manage only their own gigs.
-- create policy "Brands manage their own gigs"
--   on public.gigs
--   for all
--   using (auth.uid() = brand_id)
--   with check (auth.uid() = brand_id);
