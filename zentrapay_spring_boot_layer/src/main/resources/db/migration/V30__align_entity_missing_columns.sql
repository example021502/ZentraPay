-- ============================================================
-- V30: Align a few tables with their JPA entities for missing COLUMNS
-- (V29 handled country_code / jsonb TYPE drift; this handles column
-- PRESENCE drift). The @Entity classes are the source of truth for
-- Hibernate ddl-auto=validate. A reconcile migration (rather than editing
-- already-recorded history) keeps V1–V29 and their seed INSERTs intact.
-- ============================================================

-- 1) challenges: entity ChallengesModel maps `is_active`, but V17 created
--    and seeded the column as `active`. V17/V25 INSERTs already ran and
--    referenced `active`, so renaming here (after those) preserves the data
--    while satisfying the entity mapping.
ALTER TABLE challenges RENAME COLUMN active TO is_active;

-- 2) user_cards: entity UserCardsModel maps `currencyCode` (kept camelCase
--    intentionally to match @Column(name="currencyCode")) and `provider_id`,
--    neither of which the CREATE TABLE migration produced.
ALTER TABLE user_cards ADD COLUMN IF NOT EXISTS "currencyCode" VARCHAR(3);
ALTER TABLE user_cards ADD COLUMN IF NOT EXISTS provider_id UUID;

-- 3) user_profiles: entity UserProfileModel maps `risk_score_level`, which
--    no earlier migration added.
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS risk_score_level VARCHAR(20);
