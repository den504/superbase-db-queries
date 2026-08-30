-- =====================================================================
-- CreatorInc — Supabase / PostgreSQL schema
-- Mobile-first marketplace connecting creators and brands
-- =====================================================================
-- This file defines the core database objects for CreatorInc.
-- Run it during initial setup before applying the RLS and trigger scripts.

-- ENUMS
create type user_role as enum ('CREATOR', 'BRAND');

alter type public.user_role rename value 'CREATOR' to 'creator';
alter type public.user_role rename value 'BRAND' to 'brand';


-- ---------- CORE USER AND PROFILE TABLES ----------
-- One base profile row per Supabase auth user.
create table profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  role       user_role not null,
  email      text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Creator-specific profile data.
create table creator_profiles (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null unique references profiles(id) on delete cascade,
  display_name      text not null,
  bio               text,
  niche             text,
  profile_photo_url text,
  is_verified       boolean not null default false,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
create index idx_creator_profiles_niche on creator_profiles(niche);

-- Brand-specific profile data.
create table brand_profiles (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null unique references profiles(id) on delete cascade,
  brand_name      text not null,
  description     text,
  logo_url        text,
  website_url     text,
  contact_email   text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);


-- ---------- 6. MARKETPLACE EXTENSIONS ----------
create table public.gigs (
  id                uuid primary key default gen_random_uuid(),
  brand_id          uuid not null references auth.users(id),
  title             text not null,
  status            text not null default 'open',
  budget            numeric not null,
  brief             text not null,
  closes_at         timestamptz not null,
  requirements      text[] not null default '{}',
  deliverables      text[] not null default '{}',
  tags              text[] not null default '{}',
  interested_count  integer not null default 0,
  created_at        timestamptz not null default now()
);

create table creator_shorts (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id),
  video_url     text not null,
  thumbnail_url text not null,
  created_at    timestamptz not null default now()
);

-- ---------- 7. PERMISSIONS AND TABLE AMENDMENTS ----------
grant select, insert, update, delete on creator_shorts to authenticated;
alter table creator_shorts add column description text;


alter table public.brand_profiles rename column brand_name to company_name;
alter table public.brand_profiles rename column description to brand_intro;
alter table public.brand_profiles rename column website_url to website;

alter table public.brand_profiles add column industries text[];
alter table public.brand_profiles add column location text;
alter table public.brand_profiles add column target_creator_niches text[];

----Create RelationShip between gigs and brand_profile

alter table public.gigs
add constraint gigs_brand_profile_user_id_fkey
foreign key (brand_id)
references public.brand_profiles(user_id);


-- Create the gig_interest table and required columns:
create table public.gig_interests (
    id uuid primary key default gen_random_uuid(),
    gig_id uuid not null, creator_user_id uuid not null,
    created_at timestamptz not null default now());


-- connect interest to gigs 
alter table public.gig_interests
add constraint gig_interests_gig_id_fkey
foreign key (gig_id)
references public.gigs(id) on delete cascade;

-- connect interest to creator profile
alter table public.gig_interests
add constraint gig_interests_creator_user_id_fkey
foreign key (creator_user_id)
references public.creator_profiles(user_id) on delete cascade;

--prevent duplicate interest
alter table public.gig_interests
add constraint gig_interests_gig_creator_unique
unique (gig_id, creator_user_id);

-- NOT IN USE
-- ENUM ---
-- create type opportunity_status as enum ('DRAFT', 'OPEN', 'CLOSED', 'ARCHIVED');
-- create type interest_status as enum ('PENDING', 'ACCEPTED', 'DECLINED');
-- create type platform_type as enum ('INSTAGRAM', 'TIKTOK', 'YOUTUBE', 'X', 'FACEBOOK', 'TWITCH', 'OTHER');
-- create type upload_entity_type as enum ('CREATOR_PROFILE', 'BRAND_LOGO', 'PORTFOLIO');
-- create type audit_action as enum (
--   'LOGIN',
--   'LOGOUT',
--   'PROFILE_UPDATE',
--   'INTEREST_CREATED',
--   'INTEREST_ACCEPTED',
--   'INTEREST_DECLINED',
--   'OPPORTUNITY_CREATED',
--   'OPPORTUNITY_UPDATED',
--   'SOCIAL_ACCOUNT_CONNECTED',
--   'PHOTO_UPLOADED',
--   'CHAT_CHANNEL_CREATED'
-- );

-- NOT IN USE
-- ---------- 3. CREATOR CONTENT AND DISCOVERY TABLES ----------
-- create table portfolio_links (
--   id                 uuid primary key default gen_random_uuid(),
--   creator_profile_id uuid not null references creator_profiles(id) on delete cascade,
--   title              text,
--   url                text not null,
--   created_at         timestamptz not null default now()
-- );
-- create index idx_portfolio_links_creator on portfolio_links(creator_profile_id);

-- NOT IN USE
-- create table creator_social_accounts (
--   id                 uuid primary key default gen_random_uuid(),
--   creator_profile_id uuid not null references creator_profiles(id) on delete cascade,
--   platform           platform_type not null,
--   handle             text not null,
--   profile_url        text,
--   created_at         timestamptz not null default now(),
--   updated_at         timestamptz not null default now(),
--   unique (creator_profile_id, platform)
-- );
-- create index idx_social_accounts_creator on creator_social_accounts(creator_profile_id);

--NOT IN USE
-- create table creator_social_stats (
--   id                uuid primary key default gen_random_uuid(),
--   social_account_id uuid not null references creator_social_accounts(id) on delete cascade,
--   follower_count    integer not null check (follower_count >= 0),
--   engagement_rate   numeric(5,2) check (engagement_rate >= 0),
--   recorded_at       timestamptz not null default now()
-- );
-- create unique index uq_social_stats_account_day
--   on creator_social_stats(social_account_id, ((recorded_at at time zone 'UTC')::date));
-- create index idx_social_stats_account_time
--   on creator_social_stats(social_account_id, recorded_at desc);
-- create index idx_social_stats_follower on creator_social_stats(follower_count);

--NOT IN USE
-- ---------- 4. OPPORTUNITIES AND INTERESTS ----------
-- create table opportunities (
--   id          uuid primary key default gen_random_uuid(),
--   brand_id    uuid not null references brand_profiles(id) on delete cascade,
--   title       text not null,
--   description text,
--   budget_min  numeric(12,2) check (budget_min >= 0),
--   budget_max  numeric(12,2) check (budget_max >= 0),
--   deadline    date,
--   status      opportunity_status not null default 'DRAFT',
--   created_at  timestamptz not null default now(),
--   updated_at  timestamptz not null default now(),
--   check (budget_max is null or budget_min is null or budget_max >= budget_min)
-- );
-- create index idx_opportunities_status on opportunities(status);
-- create index idx_opportunities_brand on opportunities(brand_id);

--NOT IN USE
-- create table interests (
--   id             uuid primary key default gen_random_uuid(),
--   creator_id     uuid not null references creator_profiles(id) on delete cascade,
--   opportunity_id uuid not null references opportunities(id) on delete cascade,
--   status         interest_status not null default 'PENDING',
--   responded_at   timestamptz,
--   created_at     timestamptz not null default now(),
--   updated_at     timestamptz not null default now(),
--   unique (creator_id, opportunity_id)
-- );
-- create index idx_interests_opportunity on interests(opportunity_id);
-- create index idx_interests_creator on interests(creator_id);

--NOT IN USE
-- -- ---------- 5. COMMUNICATION AND MEDIA TABLES ----------
-- create table chat_channels (
--   id                uuid primary key default gen_random_uuid(),
--   interest_id       uuid not null unique references interests(id) on delete cascade,
--   creator_id        uuid not null references creator_profiles(id) on delete cascade,
--   brand_id          uuid not null references brand_profiles(id) on delete cascade,
--   stream_channel_id text not null unique,
--   is_active         boolean not null default true,
--   created_at        timestamptz not null default now(),
--   updated_at        timestamptz not null default now()
-- );

--NOT IN USE
-- create table photo_uploads (
--   id             uuid primary key default gen_random_uuid(),
--   owner_user_id  uuid not null references profiles(id) on delete cascade,
--   entity_type    upload_entity_type not null,
--   entity_id      uuid,
--   storage_bucket text not null,
--   storage_path   text not null,
--   public_url     text,
--   file_type      text,
--   file_size      bigint check (file_size >= 0),
--   created_at     timestamptz not null default now(),
--   unique (storage_bucket, storage_path)
-- );
-- create index idx_photo_uploads_owner on photo_uploads(owner_user_id);
-- create index idx_photo_uploads_entity on photo_uploads(entity_type, entity_id);

--NOT IN USE
-- create table audit_logs (
--   id            uuid primary key default gen_random_uuid(),
--   actor_user_id uuid references profiles(id) on delete set null,
--   action        audit_action not null,
--   entity_type   text,
--   entity_id     uuid,
--   metadata      jsonb,
--   created_at    timestamptz not null default now()
-- );
-- create index idx_audit_logs_actor on audit_logs(actor_user_id);
-- create index idx_audit_logs_action on audit_logs(action);