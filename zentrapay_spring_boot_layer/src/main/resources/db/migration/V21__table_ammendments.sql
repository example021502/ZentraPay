-- Always put comments on all responses.
-- V20 already converted users.user_type to the `user_type` enum type, which
-- now enforces the allowed values (APP_USER, MERCHANT, AGENT, OTHERS) natively.
-- A CHECK constraint is therefore neither present nor needed; this migration is
-- intentionally a safe no-op kept for version-history continuity. It only drops
-- the legacy constraint if it still exists (older databases) and never re-adds a
-- comma-broken CHECK that would conflict with the enum type.
ALTER TABLE users
    DROP CONSTRAINT IF EXISTS users_user_type_check;