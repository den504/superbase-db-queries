# Supabase DB Queries

This repository contains the SQL scripts used to set up and secure the CreatorInc database in Supabase.

## File overview

- [creatorinc_schema .sql](creatorinc_schema%20.sql) — creates the core schema, enums, tables, indexes, and a few table amendments.
- [creator_inc_function.sql](creator_inc_function.sql) — defines helper functions for auth-user creation and timestamp updates.
- [creator_inc_trigger.sql](creator_inc_trigger.sql) — wires triggers to the helper functions.
- [creator_inc_storage_policy.sql](creator_inc_storage_policy.sql) — defines Supabase Storage access policies for profile photos and creator videos.
- [creatorinc_rls.sql](creatorinc_rls.sql) — enables row-level security and defines access policies for the app's main tables.

## Suggested order of execution

1. Apply the schema file.
2. Apply the function definitions.
3. Apply the triggers.
4. Apply the storage policies.
5. Apply the RLS policies.

Each file is now grouped into logical sections with descriptive comments to make the setup easier to follow.
