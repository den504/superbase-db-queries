-- =====================================================================
-- CreatorInc — Row Level Security (RLS) Policies
-- =====================================================================
-- RLS decides WHICH ROWS each logged-in user can see or change.
-- auth.uid()  = the id of the user making the request (or null if not logged in)
-- auth.role() = 'authenticated' for logged-in users, 'anon' for anonymous
-- Pattern: every policy is "for <action> using/with check (<condition>)".
--   using      = which existing rows you may read / update / delete
--   with check = which rows you are allowed to write (insert / update)
-- =====================================================================

-- Turn RLS ON for every table. Until a policy grants access,
-- the default after this is "deny everything" — which is what we want.
alter table profiles                enable row level security;
alter table creator_profiles        enable row level security;
alter table brand_profiles          enable row level security;
alter table portfolio_links         enable row level security;
alter table creator_social_accounts enable row level security;
alter table creator_social_stats    enable row level security;
alter table opportunities           enable row level security;
alter table interests               enable row level security;
alter table chat_channels           enable row level security;
alter table photo_uploads           enable row level security;
alter table audit_logs              enable row level security;

-- ---------- PROFILES ----------
-- A user may read only their own base profile row (id = their user id).
create policy profiles_select_own on profiles
  for select using (id = auth.uid());
-- A user may update only their own base profile row.
create policy profiles_update_own on profiles
  for update using (id = auth.uid());

-- ---------- CREATOR PROFILES ----------
-- Anyone logged in can read creator profiles (brands need to discover creators).
create policy creator_read_all on creator_profiles
  for select using (auth.role() = 'authenticated');
-- A creator can insert/update/delete only the profile row that belongs to them.
create policy creator_modify_own on creator_profiles
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------- BRAND PROFILES ----------
-- Anyone logged in can read brand profiles (creators need to see who posted an opportunity).
create policy brand_read_all on brand_profiles
  for select using (auth.role() = 'authenticated');
-- A brand can insert/update/delete only its own profile row.
create policy brand_modify_own on brand_profiles
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------- OPPORTUNITIES ----------
-- Read rule: anyone can see OPEN opportunities; a brand can ALSO see its own
-- non-open ones (e.g. DRAFT / CLOSED) because it owns them.
create policy opp_read_open on opportunities
  for select using (
    status = 'OPEN'
    or brand_id in (select id from brand_profiles where user_id = auth.uid())
  );
-- Write rule: a brand can create/edit/delete only opportunities under its own brand.
create policy opp_modify_own on opportunities
  for all using (
    brand_id in (select id from brand_profiles where user_id = auth.uid())
  ) with check (
    brand_id in (select id from brand_profiles where user_id = auth.uid())
  );

-- ---------- INTERESTS ----------
-- A creator can apply (insert) only under their OWN creator profile —
-- stops anyone filing an application in someone else's name.
create policy interest_creator_insert on interests
  for insert with check (
    creator_id in (select id from creator_profiles where user_id = auth.uid())
  );
-- A creator can view their own applications.
create policy interest_creator_select on interests
  for select using (
    creator_id in (select id from creator_profiles where user_id = auth.uid())
  );
-- A brand can view interests, but only those on opportunities IT owns.
-- (Traces: my user -> my brand -> my opportunities -> interests on them.)
create policy interest_brand_select on interests
  for select using (
    opportunity_id in (
      select o.id from opportunities o
      join brand_profiles b on b.id = o.brand_id
      where b.user_id = auth.uid()
    )
  );
-- A brand can accept/decline (update) interests, but only on its own opportunities.
create policy interest_brand_update on interests
  for update using (
    opportunity_id in (
      select o.id from opportunities o
      join brand_profiles b on b.id = o.brand_id
      where b.user_id = auth.uid()
    )
  );

-- ---------- CHAT CHANNELS ----------
-- A channel's metadata is visible ONLY to the two parties in it:
-- the creator on the channel OR the brand on the channel. Nobody else.
create policy chat_visible_to_parties on chat_channels
  for select using (
    creator_id in (select id from creator_profiles where user_id = auth.uid())
    or brand_id in (select id from brand_profiles where user_id = auth.uid())
  );

-- ---------- PHOTO UPLOADS ----------
-- Anyone logged in can read upload metadata (needed to display photos).
create policy photo_read_all on photo_uploads
  for select using (auth.role() = 'authenticated');
-- A user can add/change/remove only the upload records they own.
create policy photo_modify_own on photo_uploads
  for all using (owner_user_id = auth.uid())
  with check (owner_user_id = auth.uid());

-- ---------- SOCIAL ACCOUNTS ----------
-- Readable by anyone logged in (discovery / brand search).
create policy social_read_all on creator_social_accounts
  for select using (auth.role() = 'authenticated');
-- Writable only by the creator who owns the social account.
create policy social_modify_own on creator_social_accounts
  for all using (
    creator_profile_id in (select id from creator_profiles where user_id = auth.uid())
  ) with check (
    creator_profile_id in (select id from creator_profiles where user_id = auth.uid())
  );

-- ---------- SOCIAL STATS ----------
-- Readable by anyone logged in (so brands can see follower/engagement history).
create policy stats_read_all on creator_social_stats
  for select using (auth.role() = 'authenticated');
-- Writable only by the owning creator. Stats hang off a social account,
-- so we trace: my user -> my creator profile -> my social account -> its stats.
create policy stats_modify_own on creator_social_stats
  for all using (
    social_account_id in (
      select sa.id from creator_social_accounts sa
      join creator_profiles cp on cp.id = sa.creator_profile_id
      where cp.user_id = auth.uid()
    )
  );

-- ---------- PORTFOLIO LINKS ----------
-- Readable by anyone logged in (part of a public creator profile).
create policy portfolio_read_all on portfolio_links
  for select using (auth.role() = 'authenticated');
-- Writable only by the creator who owns the portfolio.
create policy portfolio_modify_own on portfolio_links
  for all using (
    creator_profile_id in (select id from creator_profiles where user_id = auth.uid())
  ) with check (
    creator_profile_id in (select id from creator_profiles where user_id = auth.uid())
  );

-- ---------- AUDIT LOGS ----------
-- No insert/update/delete policy exists for normal users, so RLS DENIES those
-- by default. Audit rows are written by the server (service-role key), which
-- bypasses RLS. Normal users may only READ audit entries that are their own.
create policy audit_select_own on audit_logs
  for select using (actor_user_id = auth.uid());