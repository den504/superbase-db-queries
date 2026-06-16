-- =====================================================================
-- CreatorInc — Supabase / PostgreSQL Schema
-- Mobile-first iOS marketplace connecting Creators and Brands
-- =====================================================================

-- ---------- ENUMS ----------
create type user_role          as enum ('CREATOR', 'BRAND');
create type opportunity_status as enum ('DRAFT', 'OPEN', 'CLOSED', 'ARCHIVED');
create type interest_status    as enum ('PENDING', 'ACCEPTED', 'DECLINED');
create type platform_type      as enum ('INSTAGRAM', 'TIKTOK', 'YOUTUBE', 'X', 'FACEBOOK', 'TWITCH', 'OTHER');
create type upload_entity_type as enum ('CREATOR_PROFILE', 'BRAND_LOGO', 'PORTFOLIO');
create type audit_action       as enum (
  'LOGIN', 'LOGOUT', 'PROFILE_UPDATE', 'INTEREST_CREATED',
  'INTEREST_ACCEPTED', 'INTEREST_DECLINED', 'OPPORTUNITY_CREATED',
  'OPPORTUNITY_UPDATED', 'SOCIAL_ACCOUNT_CONNECTED', 'PHOTO_UPLOADED',
  'CHAT_CHANNEL_CREATED'
);

-- ---------- BASE PROFILE (1 row per auth user) ----------
create table profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  role        user_role not null,
  email       text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- ---------- CREATOR PROFILE ----------
create table creator_profiles (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null unique references profiles(id) on delete cascade,
  display_name        text not null,
  bio                 text,
  niche               text,
  profile_photo_url   text,
  is_verified         boolean not null default false,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);
create index idx_creator_profiles_niche on creator_profiles(niche);

-- ---------- BRAND PROFILE ----------
create table brand_profiles (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null unique references profiles(id) on delete cascade,
  brand_name    text not null,
  description   text,
  logo_url      text,
  website_url   text,
  contact_email text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- ---------- PORTFOLIO LINKS ----------
create table portfolio_links (
  id                  uuid primary key default gen_random_uuid(),
  creator_profile_id  uuid not null references creator_profiles(id) on delete cascade,
  title               text,
  url                 text not null,
  created_at          timestamptz not null default now()
);
create index idx_portfolio_links_creator on portfolio_links(creator_profile_id);

-- ---------- CREATOR SOCIAL ACCOUNTS ----------
create table creator_social_accounts (
  id                  uuid primary key default gen_random_uuid(),
  creator_profile_id  uuid not null references creator_profiles(id) on delete cascade,
  platform            platform_type not null,
  handle              text not null,
  profile_url         text,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  unique (creator_profile_id, platform)        -- one account per platform
);
create index idx_social_accounts_creator on creator_social_accounts(creator_profile_id);

-- ---------- CREATOR SOCIAL STATS (historical) ----------
create table creator_social_stats (
  id                  uuid primary key default gen_random_uuid(),
  social_account_id   uuid not null references creator_social_accounts(id) on delete cascade,
  follower_count      integer not null check (follower_count >= 0),
  engagement_rate     numeric(5,2) check (engagement_rate >= 0),
  recorded_at         timestamptz not null default now()
);
-- one stat row per account per day, newest-first lookups
create unique index uq_social_stats_account_day
  on creator_social_stats(social_account_id, ((recorded_at at time zone 'UTC')::date));
create index idx_social_stats_account_time
  on creator_social_stats(social_account_id, recorded_at desc);
create index idx_social_stats_follower on creator_social_stats(follower_count);

-- ---------- OPPORTUNITIES ----------
create table opportunities (
  id            uuid primary key default gen_random_uuid(),
  brand_id      uuid not null references brand_profiles(id) on delete cascade,
  title         text not null,
  description   text,
  budget_min    numeric(12,2) check (budget_min >= 0),
  budget_max    numeric(12,2) check (budget_max >= 0),
  deadline      date,
  status        opportunity_status not null default 'DRAFT',
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  check (budget_max is null or budget_min is null or budget_max >= budget_min)
);
create index idx_opportunities_status on opportunities(status);
create index idx_opportunities_brand  on opportunities(brand_id);

-- ---------- INTERESTS (creator applies to opportunity) ----------
create table interests (
  id              uuid primary key default gen_random_uuid(),
  creator_id      uuid not null references creator_profiles(id) on delete cascade,
  opportunity_id  uuid not null references opportunities(id) on delete cascade,
  status          interest_status not null default 'PENDING',
  responded_at    timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  unique (creator_id, opportunity_id)          -- can't apply twice
);
create index idx_interests_opportunity on interests(opportunity_id);
create index idx_interests_creator     on interests(creator_id);

-- ---------- CHAT CHANNELS (metadata only; messages live in Stream Chat) ----------
create table chat_channels (
  id                uuid primary key default gen_random_uuid(),
  interest_id       uuid not null unique references interests(id) on delete cascade,
  creator_id        uuid not null references creator_profiles(id) on delete cascade,
  brand_id          uuid not null references brand_profiles(id) on delete cascade,
  stream_channel_id text not null unique,
  is_active         boolean not null default true,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

-- ---------- PHOTO UPLOADS (Supabase Storage metadata) ----------
create table photo_uploads (
  id              uuid primary key default gen_random_uuid(),
  owner_user_id   uuid not null references profiles(id) on delete cascade,
  entity_type     upload_entity_type not null,
  entity_id       uuid,                          -- e.g. portfolio_link id, profile id
  storage_bucket  text not null,
  storage_path    text not null,
  public_url      text,
  file_type       text,
  file_size       bigint check (file_size >= 0),
  created_at      timestamptz not null default now(),
  unique (storage_bucket, storage_path)
);
create index idx_photo_uploads_owner on photo_uploads(owner_user_id);
create index idx_photo_uploads_entity on photo_uploads(entity_type, entity_id);

-- ---------- AUDIT LOGS ----------
create table audit_logs (
  id             uuid primary key default gen_random_uuid(),
  actor_user_id  uuid references profiles(id) on delete set null,
  action         audit_action not null,
  entity_type    text,
  entity_id      uuid,
  metadata       jsonb,
  created_at     timestamptz not null default now()
);
create index idx_audit_logs_actor  on audit_logs(actor_user_id);
create index idx_audit_logs_action on audit_logs(action);
