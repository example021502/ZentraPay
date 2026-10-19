-- V35 — ZBank Lite "link a bank" + per-user primary account.
--
-- 1. `user_bank.is_primary` mirrors the frontend's "primary" flag: one bank
--    account is primary and is displayed on the header top section of the
--    ZBank screen. A partial unique index enforces at most one primary row
--    per user (extra primaries are impossible; zero is allowed).
-- 2. The backend `banks` catalog is read-only seed data, so it stays
--    untouched — the flag lives on the per-user link row instead.
-- 3. `user_bank.link_label` stores the user-facing display name chosen in the
--    link sheet (e.g. "Salary", "Rent Fund"); nullable so older rows keep
--    working (the app falls back to the catalog bank name).

ALTER TABLE user_bank
    ADD COLUMN IF NOT EXISTS is_primary BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE user_bank
    ADD COLUMN IF NOT EXISTS link_label VARCHAR(120);

-- Backfill: each user's earliest-linked row becomes the primary, so screens
-- that expect a primary keep rendering for existing data.
UPDATE user_bank ub
SET is_primary = TRUE
WHERE ub.user_bank_id IN (
    SELECT DISTINCT ON (inner_ub.user_id) inner_ub.user_bank_id
    FROM user_bank inner_ub
    ORDER BY inner_ub.user_id, inner_ub.linked_at ASC, inner_ub.user_bank_id ASC
);

-- New users get their first linked bank promoted automatically by the link
-- endpoint rather than by this backfill.
CREATE UNIQUE INDEX IF NOT EXISTS uq_user_bank_primary_per_user
    ON user_bank (user_id)
    WHERE is_primary;
