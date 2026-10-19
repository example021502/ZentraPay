-- ============================================================
-- V24: ZGROW GAMEPLAY SETTINGS + SAVINGS LEDGER
--
-- 1. `user_gamification_settings` — stores the user's per-zone game
--    preferences. `challenges_enabled` drives whether the ZGrow challenges
--    section renders/tracks.
-- 2. `user_savings` — a professional per-currency savings ledger whose
--    `SUM(amount)` per currency is what ZGrow's hero card displays as the
--    "overall savings". Native `source` values: MILESTONE | CHALLENGE |
--    MANUAL | DEPOSIT. Rules are enforced by CHECK constraints and indexes,
--    so rows can always be filtered and aggregated safely.
-- ============================================================

-- 1. Gamification preferences (one row per user) ----------------------------
CREATE TABLE IF NOT EXISTS user_gamification_settings (
    user_id       UUID NOT NULL,
    challenges_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_user_gamification_settings PRIMARY KEY (user_id)
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_gamification_settings_user_id
    ON user_gamification_settings (user_id);
COMMENT ON TABLE user_gamification_settings IS
    'Per-user gamification preferences (challenges_enabled).';
COMMENT ON COLUMN user_gamification_settings.challenges_enabled IS
    'When FALSE the ZGrow challenges section stays collapsed and never tracks.';

-- Small "restless re-nurture" guard: never drop a user's settings on
-- schema drift, and never make a null user_id.
ALTER TABLE user_gamification_settings
    ADD CONSTRAINT fk_ugs_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;

-- 2. Savings ledger -------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_savings (
    saving_id      UUID NOT NULL DEFAULT gen_random_uuid(),
    user_id        UUID NOT NULL,
    currency_code  VARCHAR(3) NOT NULL,
    amount         DECIMAL(19, 4) NOT NULL CHECK (amount >= 0),
    source         VARCHAR(30) NOT NULL CHECK (source IN ('MILESTONE', 'CHALLENGE', 'MANUAL', 'DEPOSIT')),
    reference_id   UUID,
    note           VARCHAR(255),
    created_at     TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_user_savings PRIMARY KEY (saving_id)
);
CREATE INDEX IF NOT EXISTS idx_user_savings_user_created
    ON user_savings (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_savings_user_currency
    ON user_savings (user_id, currency_code);
COMMENT ON TABLE user_savings IS
    'Per-user savings ledger — source of truth for the "Overall Savings" hero total.';
COMMENT ON COLUMN user_savings.source IS
    'Where the saved money came from (challenge progress, manual top-up, milestone, deposit).';

-- Constraint guard (same CHECK vocabulary as the column) --------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint
                    WHERE conname = 'chk_user_savings_source'
                      AND conrelid = 'user_savings'::regclass) THEN
        ALTER TABLE user_savings
            ADD CONSTRAINT chk_user_savings_source
            CHECK (source IN ('MILESTONE', 'CHALLENGE', 'MANUAL', 'DEPOSIT'));
    END IF;
END $$;

-- Rollback for the two new tables (only effective if run before anything
-- depended on them) -----------------------------------------------------
-- DROP TABLE IF EXISTS user_savings;
-- DROP TABLE IF EXISTS user_gamification_settings;