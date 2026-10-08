-- ============================================================
-- V13: ACTIVE FLAG / COLUMN RENAMES
--
-- Brings already-migrated databases in line with the entity changes:
--   * banks.status (VARCHAR)  -> banks.active (BOOLEAN)
--   * banks.maxWeeklyValue    -> banks.max_weekly_value (snake_case,
--                                matching every other limit column)
--   * banks gains `type` and a unique `routing_number`
--   * rewards.created_on/updated_on -> rewards.created_at/updated_at
--     (`rewards` is Hibernate-created and has never had a migration, so its
--      original *_on columns are still physically present)
--   * status/user_type values normalised to the UPPERCASE convention now
--     written by UsersService ('ACTIVE' / 'INDIVIDUAL')
--
-- Every statement is guarded so this is a no-op on a database that was
-- built from the corrected V7, and correct on one that predates it.
-- ============================================================

-- ---- banks: status -> active -----------------------------------
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name = 'banks' AND column_name = 'status') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                       WHERE table_name = 'banks' AND column_name = 'active') THEN
            ALTER TABLE banks ADD COLUMN active BOOLEAN NOT NULL DEFAULT TRUE;
        END IF;
        -- Preserve intent: only rows previously flagged 'active' stay active.
        UPDATE banks SET active = (LOWER(COALESCE(status, 'active')) = 'active')
         WHERE active IS DISTINCT FROM (LOWER(COALESCE(status, 'active')) = 'active');
        ALTER TABLE banks DROP COLUMN status;
    END IF;
END $$;

-- ---- banks: added columns --------------------------------------
ALTER TABLE banks ADD COLUMN IF NOT EXISTS type VARCHAR(60);
ALTER TABLE banks ADD COLUMN IF NOT EXISTS routing_number VARCHAR(60);

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'banks' AND column_name = 'active') THEN
        ALTER TABLE banks ADD COLUMN active BOOLEAN NOT NULL DEFAULT TRUE;
    END IF;
END $$;

-- ---- banks: maxWeeklyValue -> max_weekly_value -----------------
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name = 'banks' AND column_name = 'maxWeeklyValue') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                       WHERE table_name = 'banks' AND column_name = 'max_weekly_value') THEN
            ALTER TABLE banks RENAME COLUMN "maxWeeklyValue" TO max_weekly_value;
        ELSE
            UPDATE banks SET max_weekly_value = "maxWeeklyValue"
             WHERE max_weekly_value IS NULL;
            ALTER TABLE banks DROP COLUMN "maxWeeklyValue";
        END IF;
    END IF;
END $$;

-- routing_number is unique, but NULLs must stay allowed (most gateways
-- don't publish one) and a partial unique index is what enforces that.
CREATE UNIQUE INDEX IF NOT EXISTS idx_banks_routing_number
    ON banks(routing_number) WHERE routing_number IS NOT NULL;

-- ---- rewards: created_on/updated_on -> created_at/updated_at ---
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rewards') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'rewards' AND column_name = 'created_on')
           AND NOT EXISTS (SELECT 1 FROM information_schema.columns
                           WHERE table_name = 'rewards' AND column_name = 'created_at') THEN
            ALTER TABLE rewards RENAME COLUMN created_on TO created_at;
        END IF;
        IF EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'rewards' AND column_name = 'updated_on')
           AND NOT EXISTS (SELECT 1 FROM information_schema.columns
                           WHERE table_name = 'rewards' AND column_name = 'updated_at') THEN
            ALTER TABLE rewards RENAME COLUMN updated_on TO updated_at;
        END IF;
        -- Hibernate may already have added the new names, leaving the old
        -- NOT NULL *_on columns stranded and unpopulated -> drop them.
        IF EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'rewards' AND column_name = 'created_on') THEN
            ALTER TABLE rewards DROP COLUMN created_on;
        END IF;
        IF EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'rewards' AND column_name = 'updated_on') THEN
            ALTER TABLE rewards DROP COLUMN updated_on;
        END IF;
    END IF;
END $$;

-- ---- normalise status / user_type to the UPPERCASE convention ----
UPDATE users SET status = UPPER(status) WHERE status IS NOT NULL AND status <> UPPER(status);
UPDATE users SET user_type = 'INDIVIDUAL' WHERE user_type = 'app-user';

DO $$
DECLARE
    t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY['crypto_wallets', 'accounts', 'crypto_accounts'] LOOP
        IF EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = t AND column_name = 'status') THEN
            EXECUTE format('UPDATE %I SET status = UPPER(status) WHERE status IS NOT NULL AND status <> UPPER(status)', t);
        END IF;
    END LOOP;
END $$;